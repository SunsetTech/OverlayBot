---@diagnostic disable:trailing-space
table.unpack = unpack or table.unpack

local lanes = require"lanes"
lanes = lanes.configure()
local old = require
function require(name)
	--print("require", name)
	local success, module = xpcall(
		old, function(message)
			local info = debug.getinfo(5, "Sl")
			local current_file = info.source:sub(2) -- Removes the leading '@' symbol
			local current_line = info.currentline
			
			message = message .."\n".. current_file ..": " .. current_line .."\n".. debug.traceback()
			return message
		end, name
	)
	if not success then error(module) end
	if type(module) == "table" or type(module) == "function" then
		lanes.register(name, module)
	end
	return module
end

local bit = require"bit"
local dkjson = require"dkjson"
---@class cqueues
local cqueues = require"cqueues"
cqueues.errno = require"cqueues.errno"
cqueues.socket = require"cqueues.socket"
local luv = require"luv"
local lgi = require"lgi"
local GLib = lgi.require"GLib"

local Heartstrings = require"Moonrise.Heartstrings"
local Secrets = require"Secrets"
local Census = require"Census"
local Twinge = require"Twinge"
local Roses = require"Roses"
local GLibLink = require"GLibLink"
local DataManager = require"OverlayBot.DataManager"
local Routines = require"OverlayBot.Routines"
local Configuration = Roses.Configuration.Require(nil, "OverlayBot")

local function StoreToken(NewToken)
	print"Storing new token"
	NewToken = dkjson.encode(NewToken)
	local Success = Secrets.Store(
		"OverlayBot Twinge Token",
		Secrets.Schema.Application, {
			Application = "OverlayBot";
			Purpose = "Connectivity.Twinge";
		}, nil,
		NewToken
	)
	assert(Success, "Couldn't store new token")
end

local function Main(ProcessEventPort, ControlPort, CachePath, Program, ...)
	ProcessEventPort = tonumber(ProcessEventPort) or error"Provide port for local Process Event Emitter"
	
	local _ = GLib.MainLoop(GLib.MainContext.default(), false)
	local TwitchToken
	repeat
		TwitchToken = Secrets.Lookup(
			Secrets.Schema.Application, {
				Application = "OverlayBot";
				Purpose = "Connectivity.Twinge";
			}
		)
		if not TwitchToken then
			print"Please obtain an initial token with the ObtainToken script"
			cqueues.sleep(3)
		end
	until TwitchToken
	
	TwitchToken = dkjson.decode(TwitchToken)
	Twinge.Initialize(TwitchToken, StoreToken)
	
	---@class OverlayBot.SharedData: Census.SharedData
	local SharedData = {
		Database = DataManager(Roses.Directory.User.Data"OverlayBot" .."/Bot.db");
		UserIDMap = {};
		Exited = false;
		Process = nil;
		Subprocess = {};
		Thread = {};
	}
	local CommunicationHub = lanes.linda()
	local OverlayPortal = Heartstrings.Portal(CommunicationHub)
	local GweryangRequestBox = Heartstrings.Mailbox()

	local ProcessIO = {
		In = Heartstrings.Pipe();
		Out = Heartstrings.Pipe();
		Error = Heartstrings.Pipe();
	};
	
	local Basic = require"OverlayBot.Commands.Basic"(SharedData)
	local Shenanigans = require"OverlayBot.Commands.Shenanigans"(SharedData, GweryangRequestBox, OverlayPortal)
	local CompiledCommandsGrammar = require"OverlayBot.Commands"(SharedData, Basic, Shenanigans)
	
	local _, cqueuesController = Heartstrings.Chamber{
		{
			Body = Routines.ControlServer;
			Arguments = {ControlPort, OverlayPortal};
		};
		{
			Body = Routines.Gweryang;
			Arguments = {GweryangRequestBox, CachePath};
		};
		{
			Body = Routines.IRC;
			Arguments = {
				SharedData, 
				TwitchToken,
				Configuration.IRC.Username, Configuration.IRC.Channel, Configuration.IRC.AdminUsername,
				Configuration.IRC.RedeemID,
				CompiledCommandsGrammar
			};
		};
		{
			Body = Twinge.Routines.TokenManager;
			Arguments = {TwitchToken, StoreToken};
		};
		{
			Body = Routines.Monitor.ActiveWindow;
			Arguments = {SharedData, OverlayPortal};
		};
		{
			Body = Census;
			Arguments = {
				SharedData, ProcessEventPort, 
				Program, {
					IO = ProcessIO;
					Monitor = {
						Out = true;
						Error = true;
					};
				}, ...
			};
		};
		{
			Body = Routines.Thread;
			Arguments = {
				{"ffi", "posix", "_cqueues", "luv"}, 
				Routines.Overlay, OverlayPortal
			};
		};
		{
			Body = Routines.WebClient;
			Arguments = {Configuration.WebClient.URL, Configuration.WebClient.AuthToken, SharedData.Database, Configuration.WebClient.AdminID, Shenanigans};
		};
	}
	
	-- TODO: Most of the following code is reusable, we need to figure out where to put it
	local cqueuesSleeper = luv.new_timer()
	assert(cqueuesSleeper)
	---@type function
	local cqueuesStep; function cqueuesStep()
		local Success, Error, _, Thread = cqueuesController:step(0)
		if not Success then
			print("Error in ".. tostring(Thread), Error)
			print(debug.traceback(Thread))
		end
		cqueuesSleeper:stop()
		local cqueuesTimeout = cqueuesController:timeout()
		if cqueuesTimeout ~= nil then 
			cqueuesTimeout = cqueuesTimeout * 1000
			cqueuesSleeper:start(cqueuesTimeout, 0, cqueuesStep)
		end
	end
	local cqueuesTimeout = cqueuesController:timeout()
	if cqueuesTimeout ~= nil then
		cqueuesTimeout = cqueuesTimeout * 1000
		cqueuesSleeper:start(cqueuesTimeout, 0, cqueuesStep)
	end
	local cqueuesPoller = luv.new_poll(cqueuesController:pollfd())
	assert(cqueuesPoller)
	cqueuesPoller:start("r", cqueuesStep)
	
	-- NOTE: not actually sure this is properly implemented
	local glibReady = false
	local glibContext = GLib.MainContext.default()
	local glibSleeper = luv.new_timer()
	local ArrayFD, ArrayEvents, ArrayREvents
	local glibPollers
	local Priority
	assert(glibSleeper)
	local function glibWake()
		glibReady = true
		glibSleeper:stop()
	end
	---@type function
	local function glibArm()
		local Ready
		Ready, Priority = GLibLink.Prepare(glibContext)
		local Timeout
		Timeout, ArrayFD, ArrayEvents, ArrayREvents = GLibLink.Query(glibContext, Priority)
		print("glibArm.Query", Ready, Priority, Timeout, #ArrayFD)
		if Timeout > -1 then
			glibSleeper:start(Timeout * 1000, 0, glibWake)
		end
		ArrayFD, ArrayEvents, ArrayEvents = {}, {}, {}
		glibPollers = {}
		for Index = 1, #ArrayFD do
			local PollSet = (
				(
					bit.band(ArrayEvents, lgi.GLib.IOCondition.IN) ~= 0 
					and "r" 
					or ""
				) 
				.. (
					bit.band(ArrayEvents, lgi.GLib.IOCondition.OUT) ~= 0
					and "w"
					or ""
				)
			)
			local Poller = luv.new_poll(ArrayFD[Index])
			assert(Poller, "Couldn't create poller")
			glibPollers[Index] = Poller
			Poller:start(
				PollSet, function(_, PolledEvents)
					if PolledEvents and PolledEvents:find"r" then
						ArrayREvents[Index] = bit.bor(ArrayREvents[Index], lgi.GLib.IOCondition.IN)
					end
					if PolledEvents and PolledEvents:find"w" then
						ArrayREvents[Index] = bit.bor(ArrayREvents[Index], lgi.GLib.IOCondition.OUT)
					end
					glibReady = true
				end
			)
		end
	end
	
	local glibChecker = luv.new_check()
	assert(glibChecker)
	glibChecker:start(
		function()
			if not glibReady then return false end
			glibSleeper:stop()
			for _, Poller in ipairs(glibPollers) do
				Poller:stop()
			end
			glibReady = false
			print("check", GLibLink.Check(glibContext, Priority, ArrayFD, ArrayEvents, ArrayREvents))
			print("dispatch", GLib.MainContext.dispatch(glibContext))
			glibArm()
		end
	)
	glibArm()
	
	local function Loop()
		while not SharedData.Exited do
			luv.run"once"
		end
		print"Goodbye"
	end
	return pcall(Loop)
end return Main

