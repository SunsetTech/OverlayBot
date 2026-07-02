local Utils = require"OverlayBot.Utils"
---@param SharedData OverlayBot.Routines.Overlay.Shared
---@param CommandPortal Heartstrings.Portal
local function Main(SharedData, CommandPortal)
	while true do
		local _, Message = CommandPortal:Receive()
		print("Received", Message[1], Message[2])
		local Command = Message[1]
		local Argument = Message[2]
		local Time = Utils.GetTime()
		if Command == "Hide" then
			if Argument then
				SharedData.RenderOverlay = false;
			else
				SharedData.RenderOverlay = true;
			end
		elseif Command == "Focus" then
			SharedData.FocusedWindow = Message[2]
		elseif Command == "XFlip" then
			if SharedData.XFlipEnd < Time then
				SharedData.XFlipEnd = Time
			end
			SharedData.XFlipEnd = SharedData.XFlipEnd + Argument
		elseif Command == "YFlip" then
			if SharedData.YFlipEnd < Time then
				SharedData.YFlipEnd = Time
			end
			SharedData.YFlipEnd = SharedData.YFlipEnd + Argument
		elseif Command == "Flash" then
			if SharedData.FlashEnd < Time then
				SharedData.FlashEnd = Time
			end
			SharedData.FlashEnd = SharedData.FlashEnd + Argument
		elseif Command == "Panic" then
			if SharedData.PanicEnd < Time then
				SharedData.PanicEnd = Time
			end
			SharedData.PanicEnd = SharedData.PanicEnd + Argument
		elseif Command == "BSOD" then
			if SharedData.BSODEnd < Time then
				SharedData.BSODEnd = Time
			end
			SharedData.BSODEnd = SharedData.BSODEnd + Argument
		end
	end
end; return Main
