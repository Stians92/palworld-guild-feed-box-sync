local Policy = {}

function Policy.boxAcceptsItem(filterReadValid, filterOff, itemTypeB, defs)
    if not filterReadValid then return false end
    if next(filterOff or {}) == nil then return true end
    if defs.RAW_FOOD_TYPE_B[itemTypeB] then
        if filterOff[defs.RAW_FOOD_FILTER_ID] then return false end
        for filterId in pairs(filterOff) do
            if filterId ~= defs.RAW_FOOD_FILTER_ID
                and not defs.PREPARED_FOOD_FILTER_IDS[filterId] then return false end
        end
        return true
    end
    if defs.PREPARED_FOOD_TYPE_B[itemTypeB] then
        for filterId in pairs(filterOff) do
            if defs.PREPARED_FOOD_FILTER_IDS[filterId] then return false end
            if filterId ~= defs.RAW_FOOD_FILTER_ID then return false end
        end
        return true
    end
    -- A filtered container plus unknown item metadata is not a safe target.
    return false
end

function Policy.pruneExpiredCooldowns(cooldowns, currentPass)
    for route, expiryPass in pairs(cooldowns) do
        if type(expiryPass) ~= "number" or expiryPass <= currentPass then
            cooldowns[route] = nil
        end
    end
end

return Policy
