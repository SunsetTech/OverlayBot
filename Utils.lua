---@diagnostic disable: trailing-space
local posix = require"posix"

local Utils; Utils = {
	GetTime = function()
		local Time = posix.time.clock_gettime(posix.CLOCK_MONOTONIC)
		return Time.tv_sec + Time.tv_nsec/1e9
	end;
}; return Utils;
