---@diagnostic disable:trailing-space
local Stream = require"Moonrise.Stream"
local Linux = require"Moonrise.System.Platform.Linux"
local Tools = {
	Stream = require"Moonrise.Tools.Stream";
}

---@param Shared OverlayBot.SharedData
---@param OverlayPortal Heartstrings.Portal
local function Main(Shared, OverlayPortal)
	print"Spawning focused window monitor"
	local Process, I, Out, E = Linux.Spawn(
		"Monitor-Active-Window", nil, function()
		end
	)
	local BufferedOut = Stream.Buffered(Out, 1024)
	I:Close()
	E:Close()
	
	while true do
		local Line, Stop = Tools.Stream.Read.Line(BufferedOut)
		if Stop then
			Out:Close()
			Process:Close()
			error"Monitor-Active-Window exited"
		end
		
		local PID, WindowID = Line:match("^FOCUS%s+(%d+)%s+(0x%x+)$")
		PID, WindowID = tonumber(PID), tonumber(WindowID)
		assert(PID and WindowID)
		
		if Shared.Subprocess[PID] or Shared.Thread[PID] then
			print("Focused", PID, WindowID)
			OverlayPortal:Send{"Focus", WindowID}
		else
			print"Lost focus"
		end
	end
end

return Main
