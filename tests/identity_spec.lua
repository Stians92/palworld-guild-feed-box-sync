package.path = "mod/Scripts/?.lua;" .. package.path

local Identity = require("identity")

local function equal(actual, expected, label)
    assert(actual == expected, string.format("%s: expected %s, got %s",
        label, tostring(expected), tostring(actual)))
end

equal(Identity.guildGuidString({ A = 1, B = 2, C = 3, D = 4 }),
    "00000001-00000002-00000003-00000004", "positive GUID")
equal(Identity.guildGuidString({ A = -1, B = -2147483648, C = 0, D = 4 }),
    "FFFFFFFF-80000000-00000000-00000004", "signed GUID parts")

for label, value in pairs({
    ["false"] = false,
    ["string"] = "None",
    ["zero GUID"] = { A = 0, B = 0, C = 0, D = 0 },
    ["missing part"] = { A = 1, B = 2, C = 3 },
    ["noninteger part"] = { A = 1.5, B = 2, C = 3, D = 4 },
    ["out-of-range part"] = { A = 4294967296, B = 2, C = 3, D = 4 },
}) do
    equal(Identity.guildGuidString(value), nil, label)
end

local malformed = setmetatable({}, {
    __index = function() error("unexpected reflected value") end,
})
equal(Identity.guildGuidString(malformed), nil, "throwing wrapper")

print("identity_spec.lua: all tests passed")
