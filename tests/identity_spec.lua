package.path = "mod/Scripts/?.lua;" .. package.path

local Identity = require("identity")

local function equal(actual, expected, label)
    assert(actual == expected, string.format("%s: expected %s, got %s",
        label, tostring(expected), tostring(actual)))
end

equal(Identity.validatedGuildKey("00000001-00000002-00000003-00000004"),
    "00000001-00000002-00000003-00000004", "canonical GUID")
equal(Identity.validatedGuildKey("abcdef01-23456789-aabbccdd-00000004"),
    "ABCDEF01-23456789-AABBCCDD-00000004", "lowercase normalization")

for label, value in pairs({
    ["false"] = false,
    ["string"] = "None",
    ["zero GUID"] = "00000000-00000000-00000000-00000000",
    ["missing part"] = "00000001-00000002-00000003",
    ["wrong grouping"] = "00000001-0002-0003-00000004",
    ["non-hex"] = "0000000G-00000002-00000003-00000004",
}) do
    equal(Identity.validatedGuildKey(value), nil, label)
end

equal(Identity.validatedGuildKey({}), nil, "unexpected wrapper")

print("identity_spec.lua: all tests passed")
