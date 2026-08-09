local path = "mod/Scripts/main.lua"
local file = assert(io.open(path, "rb"))
local source = file:read("*a")
file:close()

assert(source:find("LoopInGameThreadWithDelay", 1, true),
    "runtime must use a game-thread delayed-action loop")
assert(not source:find("LoopAsync", 1, true),
    "runtime must not execute Lua on UE4SS's async thread")
assert(not source:find("ExecuteInGameThread(", 1, true),
    "runtime must not queue a second game-thread callback from its loop")

print("runtime_policy_spec.lua: all tests passed")
