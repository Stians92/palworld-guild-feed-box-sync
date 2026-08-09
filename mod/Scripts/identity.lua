local Identity = {}

function Identity.validatedGuildKey(value)
    if type(value) ~= "string" then return nil end
    local a, b, c, d = value:match(
        "^(%x%x%x%x%x%x%x%x)%-(%x%x%x%x%x%x%x%x)%-(%x%x%x%x%x%x%x%x)%-(%x%x%x%x%x%x%x%x)$")
    if not (a and b and c and d) then return nil end
    local normalized = string.upper(table.concat({ a, b, c, d }, "-"))
    if normalized == "00000000-00000000-00000000-00000000" then return nil end
    return normalized
end

return Identity
