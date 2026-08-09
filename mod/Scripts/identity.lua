local Identity = {}

local UINT32 = 4294967296
local INT32_MIN = -2147483648
local UINT32_MAX = UINT32 - 1

local function uint32Part(value)
    if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then return nil end
    if value < INT32_MIN or value > UINT32_MAX then return nil end
    if value < 0 then return value + UINT32 end
    return value
end

function Identity.guildGuidString(value)
    if value == nil then return nil end

    local a, b, c, d
    local ok = pcall(function()
        a, b, c, d = value.A, value.B, value.C, value.D
    end)
    if not ok then return nil end

    a, b, c, d = uint32Part(a), uint32Part(b), uint32Part(c), uint32Part(d)
    if not (a and b and c and d) then return nil end
    if a == 0 and b == 0 and c == 0 and d == 0 then return nil end

    return string.format("%08X-%08X-%08X-%08X", a, b, c, d)
end

return Identity
