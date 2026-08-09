-- Pure deterministic redistribution planner. It performs no UObject access.

local Balance = {}

local function sortedKeys(map)
    local keys = {}
    for key in pairs(map) do table.insert(keys, key) end
    table.sort(keys)
    return keys
end

local function copyCounts(counts)
    local result = {}
    for itemId, count in pairs(counts or {}) do
        if type(count) == "number" and count > 0 then
            result[itemId] = math.floor(count)
        end
    end
    return result
end

-- Input: { { key = stable string, counts = { [itemId] = count } }, ... }
-- Output: moves plus the exact target quantities for audit/logging.
--
-- Each item is balanced independently across boxes eligible for that item. For
-- total T across N eligible boxes, the first T % N boxes in stable key order
-- receive floor(T/N)+1 and the rest floor(T/N). Ineligible boxes are untouched.
-- Thus eligible quantities differ by at most one and planning is idempotent.
function Balance.plan(boxes)
    local ordered = {}
    for _, box in ipairs(boxes or {}) do
        table.insert(ordered, {
            key = tostring(box.key),
            counts = copyCounts(box.counts),
            eligible = box.eligible or {},
        })
    end
    table.sort(ordered, function(a, b) return a.key < b.key end)

    local result = { boxes = ordered, totals = {}, targets = {}, moves = {} }
    local n = #ordered
    if n < 2 then return result end

    local itemIds = {}
    for _, box in ipairs(ordered) do
        for itemId, count in pairs(box.counts) do
            itemIds[itemId] = true
            if box.eligible[itemId] ~= false then
                result.totals[itemId] = (result.totals[itemId] or 0) + count
            end
        end
    end

    for _, itemId in ipairs(sortedKeys(itemIds)) do
        local eligibleBoxes = {}
        for _, box in ipairs(ordered) do
            if box.eligible[itemId] ~= false then table.insert(eligibleBoxes, box) end
        end
        local eligibleCount = #eligibleBoxes
        local total = result.totals[itemId] or 0
        local donors, receivers = {}, {}
        result.targets[itemId] = {}

        if eligibleCount < 2 then
            for _, box in ipairs(eligibleBoxes) do
                result.targets[itemId][box.key] = box.counts[itemId] or 0
            end
        else
            local base = math.floor(total / eligibleCount)
            local remainder = total % eligibleCount
            for index, box in ipairs(eligibleBoxes) do
                local target = base + (index <= remainder and 1 or 0)
                local current = box.counts[itemId] or 0
                result.targets[itemId][box.key] = target
                if current > target then
                    table.insert(donors, { key = box.key, remaining = current - target })
                elseif current < target then
                    table.insert(receivers, { key = box.key, remaining = target - current })
                end
            end
        end

        local donorIndex, receiverIndex = 1, 1
        while donorIndex <= #donors and receiverIndex <= #receivers do
            local donor, receiver = donors[donorIndex], receivers[receiverIndex]
            local count = math.min(donor.remaining, receiver.remaining)
            table.insert(result.moves, {
                itemId = itemId,
                count = count,
                from = donor.key,
                to = receiver.key,
            })
            donor.remaining = donor.remaining - count
            receiver.remaining = receiver.remaining - count
            if donor.remaining == 0 then donorIndex = donorIndex + 1 end
            if receiver.remaining == 0 then receiverIndex = receiverIndex + 1 end
        end

        if eligibleCount >= 2 then
            assert(donorIndex > #donors and receiverIndex > #receivers,
                "planner conservation failure for " .. itemId)
        end
    end

    return result
end

return Balance
