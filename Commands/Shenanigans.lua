local P = require"OOPEG.Nested.PEG"

--local OBS = require"OBS"
local OOP = require"Moonrise.OOP"

---@class OverlayBot.Commands.Shenanigans.Definition.Type.__Instance: OverlayBot.Commands.Shenanigans.Definition.Type
---@overload fun()

---@class OverlayBot.Commands.Shenanigans.Definition.Type
---@field Name string
---@field Parameters table?
---@overload fun(Name: string, Parameters: table?): OverlayBot.Commands.Shenanigans.Definition.Type.__Instance
local Type = OOP.Declarator.Shortcuts"OverlayBot.Commands.Shenanigans.Definition.Type"

---@param Instance OverlayBot.Commands.Shenanigans.Definition.Type
---@param Name string
---@param Parameters table?
function Type:Initialize(Instance, Name, Parameters)
	Instance.Name = Name
	Instance.Parameters = Parameters
end

---@class OverlayBot.Commands.Shenanigans.Definition
---@field Execute fun(Parameters: table<string, any>): boolean
---@field Help string
---@field CostFunction fun(Parameters: table<string, any>): integer
---@field Grammar userdata
---@field Defaults table
---@field Parameters table<string, OverlayBot.Commands.Shenanigans.Definition.Type>

---@param SharedData OverlayBot.SharedData
---@param GweryangRequestBox Heartstrings.Mailbox
---@param OverlayPortal Heartstrings.Portal
---@return table<string, OverlayBot.Commands.Shenanigans.Definition>
local function GenerateShenanigans(SharedData, GweryangRequestBox, OverlayPortal)
	---@type table<string, OverlayBot.Commands.Shenanigans.Definition>
	local Shenanigans; 
	Shenanigans = {
		-- TODO: fix these
		--
		--[[video = { 
			Execute = function(_,_,Parameters)
				local Connection = OBS.Connection(
					"192.168.1.69", 
					SharedData.Config.OBS.Password, 
					SharedData.Config.OBS.Port
				)
				Connection:Request(
					"TriggerMediaInputAction", {
						inputName = Parameters.Name;
						mediaAction = "OBS_WEBSOCKET_MEDIA_INPUT_ACTION_RESTART";
					}
				)
			end;
			Help = "Play a video. see !videolist";
			CostFunction = function(Parameters)
				return 100
			end;
			Grammar = P.Group(P.Variable.Canonical"Trailing", "Name");
			Defaults = {
				Name = "Nice";
			};
		};
		randombuddy = {
			Execute = function(_,_,Parameters)
				for i = 1, Parameters.Amount do
					table.insert(
						SharedData.Buddies, {
							X = math.random(0,1920);
							Y = math.random(0,1080);
							Scale = math.random(50,100)/100;
							DieAt = Utils.GetTime() + math.random(3,7);
							Texture = SharedData.Textures[math.random(1, #SharedData.Textures)];
						}
					)
				end
			end;
			Help = "Adds random buddies somewhere to the screen I game on for 3~7 seconds";
			CostFunction = function(Parameters)
				return Parameters.Amount * 1
			end;
			Grammar = P.Group(
				P.Variable.Canonical"Integer",
				"Amount"
			);
			Defaults = {
				Amount = 1;
			};
		};
		cheapspeak = {
			Execute = function(_, Parameters)
				local espeak = io.popen("espeak", "w")
				assert(espeak)
				espeak:write(Parameters.Message)
				espeak:close()
			end;
			Help = "cheap espeak tts. no delay. no cooldown.";
			CostFunction = function(Parameters)
				return 1 * #Parameters.Message;
			end;
			Defaults = {
				Message = "I forgot my message";
			};
			Grammar = P.Group(P.Variable.Canonical"Trailing", "Message");
		};]]
		tts = {
			Execute = function(Parameters)
				GweryangRequestBox:Send(Parameters.Message)
				return true
			end;
			CostFunction = function(Parameters)
				return 10 * #Parameters.Message;
			end;
			Parameters = {
				Message = Type"string";
			};
			Defaults = {
				Message = "[brian]I forgot my message.";
			};
			Grammar = P.Group(P.Variable.Canonical"Trailing", "Message");
			Help = "custom TTS, not yet documented";
		};
		flash = {
			Execute = function(Parameters)
				OverlayPortal:Send{"Flash", Parameters.Length}
				return true
			end;
			CostFunction = function(Parameters)
				return Parameters.Length * 100
			end;
			Parameters = {
				Length = Type("integer",{Minimum=1});
			};
			Defaults = {
				Length = 1;
			};
			Grammar = P.Group(
				P.Variable.Canonical"Integer",
				"Length"
			);
			Help = "Flashbang the streamer and viewers.";
		};
		bsod = {
			Execute = function(Parameters)
				OverlayPortal:Send{"BSOD", Parameters.Length}
				return true
			end;
			CostFunction = function(Parameters)
				return Parameters.Length * 100
			end;
			Parameters = {
				Length = Type("integer", {Minimum = 1})
			};
			Defaults = {
				Length = 1;
			};
			Grammar = P.Group(
				P.Variable.Canonical"Integer",
				"Length"
			);
			Help = "Displays Windows BSOD, on a Linux machine?";
		};
		panic = {
			Execute = function(Parameters)
				OverlayPortal:Send{"Panic", Parameters.Length}
				return true
			end;
			CostFunction = function(Parameters)
				return Parameters.Length * 100
			end;
			Parameters = {
				Length = Type("integer", {Minimum = 1});
			};
			Defaults = {
				Length = 1;
			};
			Grammar = P.Group(
				P.Variable.Canonical"Integer",
				"Length"
			);
			Help = "Displays a kernel panic D:";
		};
		xflip = {
			Execute = function(Parameters)
				OverlayPortal:Send{"XFlip", Parameters.Length}
				return true
			end;
			CostFunction = function(Parameters)
				return Parameters.Length * 100
			end;
			Parameters = {
				Length = Type("integer", {Minimum = 1});
			};
			Defaults = {
				Length = 1;
			};
			Grammar = P.Group(
				P.Variable.Canonical"Integer",
				"Length"
			);
			Help = "Flips the X axis of the game";
		};
		yflip = {
			Execute = function(Parameters)
				OverlayPortal:Send{"YFlip", Parameters.Length}
				return true
			end;
			CostFunction = function(Parameters)
				return Parameters.Length * 100
			end;
			Parameters = {
				Length = Type("integer", {Minimum = 1});
			};
			Defaults = {
				Length = 1;
			};
			Grammar = P.Group(
				P.Variable.Canonical"Integer",
				"Length"
			);
			Help = "Flips the Y axis";
		};
	}; SharedData.Shenanigans = Shenanigans; return Shenanigans
end; return GenerateShenanigans
