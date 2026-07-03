---@diagnostic disable:trailing-space
local function Main(CommandPortal)
	print"Overlay thread start"
	--local Posix = require"Moonrise.System.Platform.Posix"
	local Utils = require"OverlayBot.Utils"
	local posix = require"posix"
	local Heartstrings = require"Moonrise.Heartstrings"
	local Routines = require"OverlayBot.Routines.Overlay.Routines"

	---@class OverlayBot.Routines.Overlay.Shared
	local Shared = {
		Buddies = {};
		Hammers = {};
		Textures = {};
		TTSCooledDown = true;
		ScamTTS = false;
		FlashEnd = 0;
		BSODEnd = 0;
		PanicEnd = 0;
		XFlipEnd = 0;
		YFlipEnd = 0;
		WarpEnd = 0;
		WarpSpeed = 1;
		WarpStrength = 1;
		RenderOverlay = true;
		FocusedWindow = 0;
	}
	
	local Step = Heartstrings.Chamber{
		{
			Body = Routines.Communication;
			Arguments = {Shared, CommandPortal};
		};
		{Body = Routines.GC};
		{
			Body = Routines.Rendering;
			Arguments = {Shared};
		};
	}
	
	while true do
		local Start = Utils.GetTime()
		Step()
		local End = Utils.GetTime()
		local Elapsed = End - Start
		if 1/Elapsed < 60 then
			print("Low framerate detected", 1/Elapsed)
		end
		posix.nanosleep(0, math.max((1/60-Elapsed)*1e9, 0))
	end
end; return Main
