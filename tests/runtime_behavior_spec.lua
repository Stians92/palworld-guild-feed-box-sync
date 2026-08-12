package.path = "mod/Scripts/?.lua;" .. package.path

local Policy = require("runtime_policy")

local Defs = {
    RAW_FOOD_TYPE_B = { [47] = true },
    PREPARED_FOOD_TYPE_B = { [51] = true },
    RAW_FOOD_FILTER_ID = "Food",
    PREPARED_FOOD_FILTER_IDS = { Meal = true },
}

local function equal(actual, expected, label)
    assert(actual == expected, string.format("%s: expected %s, got %s",
        label, tostring(expected), tostring(actual)))
end

equal(Policy.boxAcceptsItem(false, {}, 47, Defs), false,
    "unknown filter state rejects raw destination")
equal(Policy.boxAcceptsItem(false, {}, 51, Defs), false,
    "unknown filter state rejects prepared destination")
equal(Policy.boxAcceptsItem(true, {}, 47, Defs), true,
    "successful empty deny list accepts raw item")
equal(Policy.boxAcceptsItem(true, {}, 51, Defs), true,
    "successful empty deny list accepts prepared item")
equal(Policy.boxAcceptsItem(true, { Food = true }, 47, Defs), false,
    "raw deny identifier rejects raw item")
equal(Policy.boxAcceptsItem(true, { Food = true }, 51, Defs), true,
    "raw deny identifier permits prepared item")
equal(Policy.boxAcceptsItem(true, { Meal = true }, 47, Defs), true,
    "meal deny identifier permits raw item")
equal(Policy.boxAcceptsItem(true, { Meal = true }, 51, Defs), false,
    "meal deny identifier rejects prepared item")
equal(Policy.boxAcceptsItem(true, { Food = true, Meal = true }, 47, Defs), false,
    "both identifiers reject raw item")
equal(Policy.boxAcceptsItem(true, { Food = true, Meal = true }, 51, Defs), false,
    "both identifiers reject prepared item")

local cooldowns = { expired = 10, boundary = 12, active = 13, malformed = "later" }
Policy.pruneExpiredCooldowns(cooldowns, 12)
equal(cooldowns.expired, nil, "expired cooldown pruned")
equal(cooldowns.boundary, nil, "boundary cooldown pruned")
equal(cooldowns.active, 13, "active cooldown retained")
equal(cooldowns.malformed, nil, "malformed cooldown pruned")

print("runtime_behavior_spec.lua: all tests passed")
