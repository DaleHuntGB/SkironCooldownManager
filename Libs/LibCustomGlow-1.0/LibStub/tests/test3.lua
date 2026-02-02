debugstack = debug.traceback
strmatch = string.match

loadfile("../LibStub.lua")()

local proxy = newproxy() -- non-string

assert(not SCMll(LibStub.NewLibrary, LibStub, proxy, 1)) -- should error, proxy is not a string, it's userdata
local success, ret = SCMll(LibStub.GetLibrary, proxy, true)
assert(not success or not ret) -- either error because proxy is not a string or because it's not actually registered.

assert(not SCMll(LibStub.NewLibrary, LibStub, "Something", "No number in here")) -- should error, minor has no string in it.

assert(not LibStub:GetLibrary("Something", true)) -- shouldn't've created it from the above statement