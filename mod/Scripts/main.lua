local Config = require("config")
local Defs = require("gamedefs")
local Balance = require("balance")
local Identity = require("identity")

local MOD = "GuildFeedBox"
local concreteByActorKey = {}
local actorByKey = {}
local discoveryPass = 0
local stableObjectKey

local function log(message)
    print(string.format("[%s] %s\n", MOD, tostring(message)))
end

local function safe(label, fn)
    local ok, value = pcall(fn)
    if not ok then log(string.format("ERROR in %s: %s", label, tostring(value))) end
    return ok, value
end

local function valid(object)
    if object == nil then return false end
    local checker
    local ok = pcall(function() checker = object.IsValid end)
    if not ok or checker == nil then return false end
    local isValid = false
    ok = pcall(function() isValid = object:IsValid() end)
    return ok and isValid
end

local function unwrap(value)
    if value == nil then return nil end
    for _ = 1, 2 do
        local unwrapped
        local ok = pcall(function() unwrapped = value:get() end)
        if not ok or unwrapped == nil or unwrapped == value then break end
        value = unwrapped
    end
    return value
end

local function booleanOrNil(value)
    if type(value) == "boolean" then return value end
    return nil
end

local function guidString(value)
    value = unwrap(value)
    local a, b, c, d
    local ok = pcall(function()
        a, b, c, d = value.A, value.B, value.C, value.D
    end)
    if ok and type(a) == "number" and type(b) == "number"
        and type(c) == "number" and type(d) == "number" then
        local function uint32(number)
            if number < 0 then return number + 4294967296 end
            return number
        end
        return string.format("%08X-%08X-%08X-%08X",
            uint32(a), uint32(b), uint32(c), uint32(d))
    end
    return nil
end

local function valueString(value)
    value = unwrap(value)
    if value == nil then return nil end
    local guid = guidString(value)
    if guid then return guid end
    local converted
    pcall(function() converted = value:ToString() end)
    if converted then return converted end
    pcall(function() converted = value:GetFullName() end)
    return converted or tostring(value)
end

local function hasReflectedMember(object, wanted, functions)
    if not valid(object) then return false end
    local found = false
    local struct = object:GetClass()
    while valid(struct) and not found do
        pcall(function()
            if functions then
                struct:ForEachFunction(function(member)
                    if member:GetFName():ToString() == wanted then found = true end
                end)
            else
                struct:ForEachProperty(function(member)
                    if member:GetFName():ToString() == wanted then found = true end
                end)
            end
        end)
        struct = struct:GetSuperStruct()
    end
    return found
end

local function firstCall(object, names)
    if not valid(object) then return nil, nil end
    for _, name in ipairs(names) do
        if hasReflectedMember(object, name, true) then
            local result
            local ok = pcall(function() result = object[name](object) end)
            result = unwrap(result)
            if ok and result ~= nil then return result, name .. "()" end
        end
    end
    return nil, nil
end

local function firstProperty(object, names)
    if not valid(object) then return nil, nil end
    for _, name in ipairs(names) do
        if hasReflectedMember(object, name, false) then
            local result
            local ok = pcall(function() result = object[name] end)
            result = unwrap(result)
            if ok and result ~= nil then return result, name end
        end
    end
    return nil, nil
end

local function firstTableValue(values)
    if type(values) ~= "table" then return nil end
    for _, value in pairs(values) do return unwrap(value) end
    return nil
end

local function firstValidTableValue(values)
    if type(values) ~= "table" then return nil end
    for _, value in pairs(values) do
        value = unwrap(value)
        if valid(value) then return value end
    end
    return nil
end

local function resolveConcreteModel(actor)
    if not valid(actor) then return nil, nil end
    local actorKey = stableObjectKey and stableObjectKey(actor) or nil
    local cached = actorKey and concreteByActorKey[actorKey] or nil
    if valid(cached) then return cached, "BP_OnSetConcreteModel hook" end
    if hasReflectedMember(actor, "TryGetConcreteModel", true) then
        local outputPin, concreteModel
        local ok = pcall(function() outputPin, concreteModel = actor:TryGetConcreteModel() end)
        concreteModel = unwrap(concreteModel)
        if ok and valid(concreteModel) then
            return concreteModel, "TryGetConcreteModel() second return"
        end
        outputPin = unwrap(outputPin)
        if ok and valid(outputPin) then return outputPin, "TryGetConcreteModel() return" end

        local out = {}
        local result
        ok = pcall(function() result = actor:TryGetConcreteModel(out) end)
        local value = firstTableValue(out)
        if ok and valid(value) then return value, "TryGetConcreteModel(out)" end
        result = unwrap(result)
        if ok and valid(result) then return result, "TryGetConcreteModel(out) return" end

        local outPin, outModel = {}, {}
        ok = pcall(function() result = actor:TryGetConcreteModel(outPin, outModel) end)
        value = firstTableValue(outModel)
        if ok and valid(value) then return value, "TryGetConcreteModel(outPin, outModel)" end
    end
    local value, path = firstCall(actor, Defs.MODEL_FUNCTIONS)
    if value ~= nil then return value, path end
    return firstProperty(actor, Defs.MODEL_PROPERTIES)
end

local function firstAccess(object, functions, properties)
    local value, path = firstCall(object, functions)
    if value ~= nil then return value, path end
    return firstProperty(object, properties)
end

stableObjectKey = function(object)
    local key
    pcall(function() key = object:GetFullName() end)
    return key or tostring(object)
end

local function readCounts(container)
    local counts = {}
    if not valid(container) then return counts, "invalid container" end
    local slots, slotPath = firstProperty(container, Defs.SLOT_ARRAY_PROPERTIES)
    if slots == nil then return counts, "slot array not found" end
    local ok, err = pcall(function()
        slots:ForEach(function(_, element)
            local slot = unwrap(element)
            if valid(slot) then
                local itemId, count
                pcall(function() itemId = slot.ItemId.StaticId:ToString() end)
                pcall(function() count = slot.StackCount end)
                if itemId and itemId ~= "None" and type(count) == "number" and count > 0 then
                    counts[itemId] = (counts[itemId] or 0) + count
                end
            end
        end)
    end)
    if not ok then return {}, tostring(err) end
    return counts, slotPath
end

local function addNames(result, values, depth)
    if depth > 3 then return end
    values = unwrap(values)
    if values == nil or type(values) == "boolean" then return end

    if type(values) == "string" then
        if values ~= "" then result[values] = true end
        return
    end
    if type(values) == "table" then
        for _, value in pairs(values) do addNames(result, value, depth + 1) end
        return
    end

    local iterated = false
    pcall(function()
        values:ForEach(function(_, element)
            iterated = true
            addNames(result, element, depth + 1)
        end)
    end)
    if iterated then return end

    local length
    pcall(function() length = #values end)
    if type(length) == "number" and length > 0 then
        for index = 1, length do
            local element
            pcall(function() element = values[index] end)
            addNames(result, element, depth + 1)
        end
        return
    end

    local name
    pcall(function() name = values:ToString() end)
    if type(name) == "string" and name ~= "" then result[name] = true end
end

local function readFilterOffSet(container)
    local result = {}
    if not valid(container) then return result, "invalid container" end

    local first, second
    local ok = pcall(function() first, second = container:GetFilterOffList() end)
    local diagnostic = string.format("direct=%s first=%s/%s second=%s/%s",
        tostring(ok), type(first), tostring(first), type(second), tostring(second))
    if ok then
        addNames(result, first, 0)
        addNames(result, second, 0)
    end
    if next(result) ~= nil then return result, diagnostic end

    -- Some UE4SS builds expose Unreal output parameters through a Lua table.
    local out = {}
    ok = pcall(function() first, second = container:GetFilterOffList(out) end)
    diagnostic = diagnostic .. string.format(" out=%s/%s result=%s/%s,%s/%s",
        tostring(ok), tostring(out), type(first), tostring(first), type(second), tostring(second))
    if ok then
        addNames(result, out, 0)
        addNames(result, first, 0)
        addNames(result, second, 0)
    end
    return result, diagnostic
end

local function readSlotItemTypeB(slot)
    local first, second
    local ok = pcall(function() first, second = slot:TryGetStaticItemData() end)
    first, second = unwrap(first), unwrap(second)
    local staticData = valid(second) and second or (valid(first) and first or nil)
    if not valid(staticData) then
        local out = {}
        ok = pcall(function() first, second = slot:TryGetStaticItemData(out) end)
        local outValue = firstValidTableValue(out)
        first, second = unwrap(first), unwrap(second)
        if ok then
            staticData = valid(outValue) and outValue
                or (valid(second) and second or (valid(first) and first or nil))
        end
    end
    if not valid(staticData) then return nil end
    local typeB
    pcall(function() typeB = unwrap(staticData.TypeB) end)
    if type(typeB) == "number" then return typeB end
    return tonumber(tostring(typeB))
end

local function readSlots(container)
    local result = {}
    if not valid(container) then return result end
    local slots = firstProperty(container, Defs.SLOT_ARRAY_PROPERTIES)
    if slots == nil then return result end
    local containerId
    pcall(function() containerId = container:GetId() end)
    local containerGuid
    pcall(function() containerGuid = guidString(containerId.ID) end)
    pcall(function()
        slots:ForEach(function(_, element)
            local slot = unwrap(element)
            if valid(slot) then
                local itemId, count, maxStack, isMaxStack, isEmpty, slotId, itemTypeB
                local propertyIndex, slotIdIndex, propertyContainerGuid, slotIdContainerGuid
                pcall(function() itemId = slot.ItemId.StaticId:ToString() end)
                pcall(function() count = slot:GetStackCount() end)
                if type(count) ~= "number" then pcall(function() count = slot.StackCount end) end
                pcall(function() maxStack = slot:GetMaxStack() end)
                pcall(function() isMaxStack = slot:IsMaxStack() end)
                pcall(function() isEmpty = slot:IsEmpty() end)
                pcall(function() slotId = slot:GetSlotId() end)
                pcall(function() propertyIndex = slot.SlotIndex end)
                pcall(function() propertyContainerGuid = guidString(slot.ContainerId.ID) end)
                pcall(function() slotIdIndex = slotId.SlotIndex end)
                pcall(function() slotIdContainerGuid = guidString(slotId.ContainerId.ID) end)
                if itemId and itemId ~= "None" then itemTypeB = readSlotItemTypeB(slot) end
                table.insert(result, {
                    object = slot,
                    slotId = slotId,
                    itemId = itemId or "None",
                    count = type(count) == "number" and count or 0,
                    maxStack = type(maxStack) == "number" and maxStack or nil,
                    isMaxStack = booleanOrNil(isMaxStack),
                    isMaxStackRaw = tostring(isMaxStack),
                    isEmpty = booleanOrNil(isEmpty),
                    isEmptyRaw = tostring(isEmpty),
                    propertyIndex = type(propertyIndex) == "number" and propertyIndex or nil,
                    slotIdIndex = type(slotIdIndex) == "number" and slotIdIndex or nil,
                    containerGuid = containerGuid,
                    propertyContainerGuid = propertyContainerGuid,
                    slotIdContainerGuid = slotIdContainerGuid,
                    itemTypeB = itemTypeB,
                })
            end
        end)
    end)
    return result
end

local function resolveBox(actor)
    local box = { actor = actor, key = stableObjectKey(actor) }
    box.model, box.modelPath = resolveConcreteModel(actor)
    local owner = valid(box.model) and box.model or actor
    box.module, box.modulePath = firstAccess(owner,
        Defs.CONTAINER_MODULE_FUNCTIONS, Defs.CONTAINER_MODULE_PROPERTIES)
    if not valid(box.module) then
        box.module, box.modulePath = firstAccess(actor,
            Defs.CONTAINER_MODULE_FUNCTIONS, Defs.CONTAINER_MODULE_PROPERTIES)
    end
    box.container, box.containerPath = firstAccess(box.module,
        Defs.CONTAINER_FUNCTIONS, Defs.CONTAINER_PROPERTIES)
    box.access, box.accessPath = firstCall(owner, Defs.CONTAINER_ACCESS_FUNCTIONS)
    box.base, box.basePath = firstAccess(owner, Defs.BASE_FUNCTIONS, Defs.BASE_PROPERTIES)
    if not valid(box.base) then
        box.base, box.basePath = firstAccess(actor, Defs.BASE_FUNCTIONS, Defs.BASE_PROPERTIES)
    end
    -- The actor API is preferable: F8 verified GetGroupIdBelongTo on
    -- PalMapObject, and it avoids chasing a base-model wrapper.
    box.guild, box.guildPath = firstAccess(actor, Defs.GUILD_FUNCTIONS, {})
    if box.guild == nil then
        local guildOwner = valid(box.base) and box.base or owner
        box.guild, box.guildPath = firstAccess(guildOwner, Defs.GUILD_FUNCTIONS, Defs.GUILD_PROPERTIES)
    end
    -- Only a concrete, nonzero FGuid may group boxes. Unexpected reflected
    -- values stay unresolved and are isolated by groupedPlans.
    box.guildKey = Identity.validatedGuildKey(valueString(box.guild))
    box.counts, box.slotPath = readCounts(box.container)
    box.slots = readSlots(box.container)
    box.filterOff, box.filterDiagnostic = readFilterOffSet(box.container)
    return box
end

local function refreshActorCache()
    local refreshed = {}
    for _, definition in ipairs(Defs.FEED_BOX_CLASSES) do
        if not definition.cooled or Config.INCLUDE_COOLED_FEED_BOX then
            local found = FindAllOf(definition.class)
            if found then
                for _, actor in ipairs(found) do
                    if valid(actor) then refreshed[stableObjectKey(actor)] = actor end
                end
            end
        end
    end
    actorByKey = refreshed
    discoveryPass = 0
end

local function discoverBoxes(forceRefresh)
    discoveryPass = discoveryPass + 1
    if forceRefresh or next(actorByKey) == nil
        or discoveryPass >= Config.FULL_DISCOVERY_EVERY_PASSES then
        refreshActorCache()
    end

    local boxes = {}
    for key, actor in pairs(actorByKey) do
        if valid(actor) then
            table.insert(boxes, resolveBox(actor))
        else
            actorByKey[key] = nil
            concreteByActorKey[key] = nil
        end
    end
    table.sort(boxes, function(a, b) return a.key < b.key end)
    return boxes
end

local function boxAcceptsItem(box, itemTypeB)
    if next(box.filterOff or {}) == nil then return true end
    if Defs.RAW_FOOD_TYPE_B[itemTypeB] then
        if box.filterOff[Defs.RAW_FOOD_FILTER_ID] then return false end
        for filterId in pairs(box.filterOff) do
            if filterId ~= Defs.RAW_FOOD_FILTER_ID
                and not Defs.PREPARED_FOOD_FILTER_IDS[filterId] then return false end
        end
        return true
    end
    if Defs.PREPARED_FOOD_TYPE_B[itemTypeB] then
        for filterId in pairs(box.filterOff) do
            if Defs.PREPARED_FOOD_FILTER_IDS[filterId] then return false end
            if filterId ~= Defs.RAW_FOOD_FILTER_ID then return false end
        end
        return true
    end
    -- A filtered container plus unknown item metadata is not a safe target.
    return false
end

local function groupedPlans(boxes)
    local groups = {}
    for _, box in ipairs(boxes) do
        -- Never mix unresolved ownership. Each unresolved box gets its own
        -- group, producing no moves rather than crossing guild boundaries.
        local groupKey = box.guildKey or ("UNRESOLVED:" .. box.key)
        groups[groupKey] = groups[groupKey] or { boxes = {}, itemTypes = {} }
        table.insert(groups[groupKey].boxes, box)
        for _, slot in ipairs(box.slots or {}) do
            if slot.itemId ~= "None" and slot.itemTypeB ~= nil then
                groups[groupKey].itemTypes[slot.itemId] = slot.itemTypeB
            end
        end
    end
    local plans = {}
    for groupKey, group in pairs(groups) do
        local itemIds = {}
        for _, box in ipairs(group.boxes) do
            for itemId in pairs(box.counts) do itemIds[itemId] = true end
        end
        local plannerBoxes = {}
        for _, box in ipairs(group.boxes) do
            local eligible = {}
            for itemId in pairs(itemIds) do
                eligible[itemId] = boxAcceptsItem(box, group.itemTypes[itemId])
            end
            table.insert(plannerBoxes, { key = box.key, counts = box.counts, eligible = eligible })
        end
        plans[groupKey] = Balance.plan(plannerBoxes)
    end
    return plans
end

local function sortedMapKeys(values)
    local keys = {}
    for key in pairs(values or {}) do table.insert(keys, key) end
    table.sort(keys)
    return keys
end

local function findFirstCandidate(classNames)
    for _, className in ipairs(classNames) do
        local object = FindFirstOf(className)
        if valid(object) then return object end
    end
    return nil
end

local function getNetworkItemComponent()
    local transmitter = findFirstCandidate(Defs.NETWORK_TRANSMITTER_CLASSES)
    if not valid(transmitter) then return nil end
    local item = firstCall(transmitter, { "GetItem" })
    if valid(item) then return item end
    item = firstProperty(transmitter, { "Item" })
    return valid(item) and item or nil
end

local function newGuid()
    local library = StaticFindObject(Defs.KISMET_GUID_LIBRARY)
    if not valid(library) then return nil end
    local guid
    pcall(function() guid = library:NewGuid() end)
    return guid
end

local function findSourceSlot(box, itemId)
    for _, slot in ipairs(box.slots or {}) do
        if slot.itemId == itemId and slot.count > 0 and slot.slotId ~= nil then return slot end
    end
    return nil
end

local function findDestinationSlot(box, itemId)
    local empty
    for _, slot in ipairs(box.slots or {}) do
        if slot.slotId ~= nil then
            local hasCapacity = slot.isMaxStack == false
                or (slot.isMaxStack == nil and slot.maxStack ~= nil and slot.count < slot.maxStack)
            if slot.itemId == itemId and slot.count > 0 and hasCapacity then
                return slot
            elseif (slot.itemId == "None" or slot.count == 0) and empty == nil then
                empty = slot
            end
        end
    end
    return empty
end

local function hasServerAuthority(boxes)
    for _, box in ipairs(boxes or {}) do
        if valid(box.actor) and hasReflectedMember(box.actor, "HasAuthority", true) then
            local authority
            local ok = pcall(function() authority = box.actor:HasAuthority() end)
            if ok and type(authority) == "boolean" then return authority end
        end
    end
    -- Failing closed is important: an API change must not turn clients into
    -- competing redistribution workers.
    return false
end

local function destinationCapacity(destination, source)
    local maxStack = destination.maxStack
    if destination.count == 0 and (type(maxStack) ~= "number" or maxStack <= 0) then
        maxStack = source.maxStack
    end
    if type(maxStack) ~= "number" or maxStack <= 0 then
        return Config.MAX_ITEMS_PER_REQUEST
    end
    return math.max(0, maxStack - destination.count)
end

local routeCooldownUntil = {}
local balancePass = 0

local function routeKey(groupKey, move)
    return table.concat({ groupKey, move.itemId, move.from, move.to }, "\n")
end

local function selectPlannedTransfer(boxes, requestLimit, requireEmptyDestination)
    local byKey = {}
    for _, box in ipairs(boxes) do byKey[box.key] = box end
    local plans = groupedPlans(boxes)
    local plannedCount = 0
    local coolingCount = 0
    local selected

    for _, groupKey in ipairs(sortedMapKeys(plans)) do
        local plan = plans[groupKey]
        plannedCount = plannedCount + #plan.moves
        for _, move in ipairs(plan.moves) do
            local moveRouteKey = routeKey(groupKey, move)
            if (routeCooldownUntil[moveRouteKey] or 0) > balancePass then
                coolingCount = coolingCount + 1
            else
                local sourceBox, destinationBox = byKey[move.from], byKey[move.to]
                if sourceBox and destinationBox then
                    local source = findSourceSlot(sourceBox, move.itemId)
                    local destination = findDestinationSlot(destinationBox, move.itemId)
                    if source and destination
                        and (not requireEmptyDestination or destination.count == 0) then
                        local count = math.min(move.count, source.count,
                            destinationCapacity(destination, source), requestLimit)
                        if count > 0 then
                            local candidate = {
                                move = move,
                                sourceBox = sourceBox,
                                destinationBox = destinationBox,
                                source = source,
                                destination = destination,
                                count = math.floor(count),
                                groupKey = groupKey,
                            }
                            local candidateKey = moveRouteKey
                            local selectedKey = selected and routeKey(selected.groupKey, selected.move) or nil
                            if selected == nil or candidate.count > selected.count
                                or (candidate.count == selected.count and candidateKey < selectedKey) then
                                selected = candidate
                            end
                        end
                    end
                end
            end
        end
    end
    return selected, plannedCount, coolingCount
end

local function slotIdentityIsConsistent(slot)
    if slot.slotId == nil or slot.propertyIndex == nil or slot.slotIdIndex == nil then return false end
    if slot.propertyIndex ~= slot.slotIdIndex then return false end
    if not (slot.containerGuid and slot.propertyContainerGuid and slot.slotIdContainerGuid) then return false end
    return slot.containerGuid == slot.propertyContainerGuid
        and slot.containerGuid == slot.slotIdContainerGuid
end

local function submitTransfer(selected, label)
    if not slotIdentityIsConsistent(selected.source)
        or not slotIdentityIsConsistent(selected.destination) then
        log(label .. " refused: source or destination slot identity is inconsistent")
        return false
    end
    local networkItem = getNetworkItemComponent()
    local requestId = newGuid()
    if not (valid(networkItem) and requestId ~= nil) then
        log(label .. " missing network item component or request GUID")
        return false
    end

    log(string.format("%s: requesting %s x%d: %s -> %s (guild %s, mode=exact-slot)",
        label, selected.move.itemId, selected.count, selected.move.from,
        selected.move.to, selected.groupKey))
    local ok, err = pcall(function()
        local froms = { { SlotId = selected.source.slotId, Num = selected.count } }
        networkItem:RequestMove_ToServer(requestId, selected.destination.slotId, froms)
    end)
    if not ok then
        log(label .. " transfer call failed: " .. tostring(err))
        return false
    end
    return true
end

local lastBalanceState
local readinessSignature
local readinessPasses = 0
local readinessDiagnosticSignature
local pendingTransfer

local function logBalanceState(state, message)
    if lastBalanceState ~= state then
        lastBalanceState = state
        log(message)
    end
end

local function checkAutomaticReadiness(boxes)
    local keys = {}
    for _, box in ipairs(boxes) do
        if not (valid(box.actor) and valid(box.container) and box.guildKey
            and box.slots and #box.slots > 0) then
            readinessSignature = nil
            readinessPasses = 0
            return false
        end
        table.insert(keys, box.key)
    end
    table.sort(keys)
    local signature = table.concat(keys, "\n")
    if signature ~= readinessSignature then
        readinessSignature = signature
        readinessPasses = 1
    else
        readinessPasses = readinessPasses + 1
    end
    return readinessPasses >= Config.READINESS_PASSES
end

local function logReadinessDiagnostics(boxes)
    if readinessDiagnosticSignature == readinessSignature then return end
    readinessDiagnosticSignature = readinessSignature
    log(string.format("balance ready with %d Feed Boxes; reporting filter snapshot", #boxes))
    for _, box in ipairs(boxes) do
        local itemTypes = {}
        for _, slot in ipairs(box.slots or {}) do
            if slot.itemId ~= "None" then
                itemTypes[slot.itemId] = tostring(slot.itemTypeB)
            end
        end
        local typeDescriptions = {}
        for itemId, itemTypeB in pairs(itemTypes) do
            table.insert(typeDescriptions, itemId .. ":" .. itemTypeB)
        end
        table.sort(typeDescriptions)
        log(string.format("READY box=%s filters=[%s] itemTypes=[%s] shape={%s}", box.key,
            table.concat(sortedMapKeys(box.filterOff), ","),
            table.concat(typeDescriptions, ","), box.filterDiagnostic or "?"))
    end
end

local function verifyPendingTransfer(boxes)
    if pendingTransfer == nil then return end
    local destinationBox
    for _, box in ipairs(boxes) do
        if box.key == pendingTransfer.destinationBoxKey then destinationBox = box break end
    end
    local destinationSlot
    for _, slot in ipairs(destinationBox and destinationBox.slots or {}) do
        if slot.slotIdIndex == pendingTransfer.destinationSlotIndex then
            destinationSlot = slot
            break
        end
    end

    local applied = destinationSlot
        and destinationSlot.itemId == pendingTransfer.itemId
        and destinationSlot.count > pendingTransfer.destinationCountBefore
    if applied then
        routeCooldownUntil[pendingTransfer.routeKey] = nil
        log(string.format("BALANCE verified %s destination increase %d -> %d",
            pendingTransfer.itemId, pendingTransfer.destinationCountBefore, destinationSlot.count))
    else
        routeCooldownUntil[pendingTransfer.routeKey] = balancePass + Config.ROUTE_COOLDOWN_PASSES
        log(string.format(
            "BALANCE did not observe %s at destination; route cooling down for %d passes",
            pendingTransfer.itemId, Config.ROUTE_COOLDOWN_PASSES))
    end
    pendingTransfer = nil
end

local function runBalanceTick()
    local tickStarted = os.clock()
    local snapshotMs, planMs, submitMs = 0, 0, 0
    local function finishPerformance(state, boxCount)
        local totalMs = (os.clock() - tickStarted) * 1000
        if totalMs >= Config.PERF_LOG_THRESHOLD_MS then
            log(string.format(
                "PERF state=%s total=%.2fms snapshot=%.2fms plan=%.2fms submit=%.2fms boxes=%d",
                state, totalMs, snapshotMs, planMs, submitMs, boxCount or 0))
        end
    end

    balancePass = balancePass + 1
    local boxes = discoverBoxes()
    snapshotMs = (os.clock() - tickStarted) * 1000
    if #boxes < 2 then
        readinessSignature = nil
        readinessPasses = 0
        logBalanceState("insufficient-boxes", "balance waiting for at least two loaded Feed Boxes")
        finishPerformance("insufficient-boxes", #boxes)
        return
    end
    if not hasServerAuthority(boxes) then
        logBalanceState("not-authority", "balance inactive: this process has no server authority")
        finishPerformance("not-authority", #boxes)
        return
    end
    verifyPendingTransfer(boxes)
    if not checkAutomaticReadiness(boxes) then
        logBalanceState("warming-up",
            string.format("balance waiting for %d stable world-readiness passes", Config.READINESS_PASSES))
        finishPerformance("warming-up", #boxes)
        return
    end
    logReadinessDiagnostics(boxes)

    local planStarted = os.clock()
    local selected, plannedCount, coolingCount = selectPlannedTransfer(
        boxes, Config.MAX_ITEMS_PER_REQUEST)
    planMs = (os.clock() - planStarted) * 1000
    local state
    if selected then
        state = "moving"
        lastBalanceState = "moving"
        local submitStarted = os.clock()
        if submitTransfer(selected, "BALANCE") then
            pendingTransfer = {
                routeKey = routeKey(selected.groupKey, selected.move),
                itemId = selected.move.itemId,
                destinationBoxKey = selected.destinationBox.key,
                destinationSlotIndex = selected.destination.slotIdIndex,
                destinationCountBefore = selected.destination.count,
            }
        end
        submitMs = (os.clock() - submitStarted) * 1000
    elseif plannedCount == 0 then
        state = "balanced"
        logBalanceState("balanced", "balance complete for all loaded guild Feed Boxes")
    else
        state = "capacity-blocked"
        logBalanceState("capacity-blocked",
            string.format("balance paused: %d planned moves; %d routes cooling down or awaiting capacity",
                plannedCount, coolingCount))
    end
    finishPerformance(state, #boxes)
end

local feedBoxClassSet = {}
for _, definition in ipairs(Defs.FEED_BOX_CLASSES) do
    feedBoxClassSet[definition.class] = not definition.cooled or Config.INCLUDE_COOLED_FEED_BOX
end

safe("register concrete-model hook", function()
    RegisterHook("/Script/Pal.PalMapObject:BP_OnSetConcreteModel", function(self, modelParam)
        safe("capture concrete model", function()
            local actor = unwrap(self)
            local model = unwrap(modelParam)
            if not (valid(actor) and valid(model)) then return end
            local className = actor:GetClass():GetFName():ToString()
            if feedBoxClassSet[className] then
                local key = stableObjectKey(actor)
                actorByKey[key] = actor
                concreteByActorKey[key] = model
                log(string.format("captured concrete model for %s: %s class=%s",
                    key, stableObjectKey(model), model:GetClass():GetFName():ToString()))
            end
        end)
    end)
end)

local balanceLoopHandle
local balanceLoopStarted = false
if Config.ENABLE_TRANSFERS then
    local ok = safe("start balance loop", function()
        if type(LoopInGameThreadWithDelay) ~= "function" then
            error("UE4SS Delayed Actions API is unavailable; automatic transfers disabled")
        end
        balanceLoopHandle = LoopInGameThreadWithDelay(Config.BALANCE_INTERVAL_MS, function()
            safe("balance tick", runBalanceTick)
        end)
        if type(balanceLoopHandle) ~= "number" then
            error("UE4SS did not create the balance loop; automatic transfers disabled")
        end
        log("game-thread balance loop started; handle=" .. tostring(balanceLoopHandle))
    end)
    balanceLoopStarted = ok and type(balanceLoopHandle) == "number"
end

log(string.format("loaded production build. automatic transfers=%s interval=%dms.",
    tostring(balanceLoopStarted), Config.BALANCE_INTERVAL_MS))
