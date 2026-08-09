package.path = "mod/Scripts/?.lua;" .. package.path

local Balance = require("balance")

local function equal(actual, expected, label)
    assert(actual == expected, string.format("%s: expected %s, got %s", label, expected, actual))
end

local plan = Balance.plan({
    { key = "base-c", counts = { BakedBerries = 1 } },
    { key = "base-a", counts = { BakedBerries = 8, JamBun = 1 } },
    { key = "base-b", counts = {} },
})

equal(plan.totals.BakedBerries, 9, "berry conservation")
equal(plan.targets.BakedBerries["base-a"], 3, "berry target a")
equal(plan.targets.BakedBerries["base-b"], 3, "berry target b")
equal(plan.targets.BakedBerries["base-c"], 3, "berry target c")
equal(plan.targets.JamBun["base-a"], 1, "remainder target a")
equal(plan.targets.JamBun["base-b"], 0, "remainder target b")
equal(plan.targets.JamBun["base-c"], 0, "remainder target c")
equal(#plan.moves, 2, "move count")

local simulated = {}
for _, box in ipairs(plan.boxes) do
    simulated[box.key] = {}
    for itemId, count in pairs(box.counts) do simulated[box.key][itemId] = count end
end
for _, move in ipairs(plan.moves) do
    simulated[move.from][move.itemId] = (simulated[move.from][move.itemId] or 0) - move.count
    simulated[move.to][move.itemId] = (simulated[move.to][move.itemId] or 0) + move.count
end
for itemId, targets in pairs(plan.targets) do
    for boxKey, target in pairs(targets) do
        equal(simulated[boxKey][itemId] or 0, target, "simulated target " .. itemId .. "/" .. boxKey)
    end
end

local balanced = Balance.plan({
    { key = "a", counts = { Berries = 2 } },
    { key = "b", counts = { Berries = 2 } },
})
equal(#balanced.moves, 0, "idempotent balanced input")

local sparse = Balance.plan({
    { key = "a", counts = { Berries = 2 } },
    { key = "b", counts = {} },
    { key = "c", counts = {} },
})
equal(sparse.targets.Berries.a, 1, "deterministic remainder a")
equal(sparse.targets.Berries.b, 1, "deterministic remainder b")
equal(sparse.targets.Berries.c, 0, "deterministic remainder c")

local filtered = Balance.plan({
    { key = "a", counts = { Berries = 8 }, eligible = { Berries = true } },
    { key = "b", counts = { Berries = 7 }, eligible = { Berries = false } },
    { key = "c", counts = {}, eligible = { Berries = true } },
})
equal(filtered.totals.Berries, 8, "filtered total excludes ineligible box")
equal(filtered.targets.Berries.a, 4, "filtered target a")
equal(filtered.targets.Berries.b, nil, "filtered target leaves b untouched")
equal(filtered.targets.Berries.c, 4, "filtered target c")
equal(#filtered.moves, 1, "filtered move count")
equal(filtered.moves[1].count, 4, "filtered move quantity")

local isolated = Balance.plan({
    { key = "a", counts = { Berries = 9 }, eligible = { Berries = false } },
    { key = "b", counts = {}, eligible = { Berries = true } },
})
equal(isolated.totals.Berries, nil, "isolated filtered item has no eligible total")
equal(#isolated.moves, 0, "isolated filtered item does not move")

print("balance_spec.lua: all tests passed")
