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
---@field Execute fun(Parameters: table<string, any>, ResultBox: Heartstrings.Mailbox)
---@field Description string
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
			Description = "Play a video. see !videolist";
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
			Description = "Adds random buddies somewhere to the screen I game on for 3~7 seconds";
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
			Description = "cheap espeak tts. no delay. no cooldown.";
			CostFunction = function(Parameters)
				return 1 * #Parameters.Message;
			end;
			Defaults = {
				Message = "I forgot my message";
			};
			Grammar = P.Group(P.Variable.Canonical"Trailing", "Message");
		};]]
		tts = {
			Execute = function(Parameters, ResultBox)
				GweryangRequestBox:Send{Parameters.Message, ResultBox}
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
			Description = "custom TTS, not yet documented";
		};
		flash = {
			Execute = function(Parameters, ResultBox)
				OverlayPortal:Send{"Flash", Parameters.Length}
				ResultBox:Send{true}
			end;
			CostFunction = function(Parameters)
				return Parameters.Length ^ 2 * 100
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
			Description = "Flashbang the streamer and viewers.";
		};
		bsod = {
			Execute = function(Parameters, ResultBox)
				OverlayPortal:Send{"BSOD", Parameters.Length}
				ResultBox:Send{true}
			end;
			CostFunction = function(Parameters)
				return Parameters.Length ^ 2 * 100
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
			Description = "Displays Windows BSOD, on a Linux machine?";
		};
		panic = {
			Execute = function(Parameters, ResultBox)
				OverlayPortal:Send{"Panic", Parameters.Length}
				ResultBox:Send{true}
			end;
			CostFunction = function(Parameters)
				return Parameters.Length ^ 2 * 100
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
			Description = "Displays a kernel panic D:";
		};
		xflip = {
			Execute = function(Parameters, ResultBox)
				OverlayPortal:Send{"XFlip", Parameters.Length}
				ResultBox:Send{true}
			end;
			CostFunction = function(Parameters)
				return Parameters.Length ^ 2 * 100
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
			Description = "Flips the X axis of the game";
		};
		yflip = {
			Execute = function(Parameters, ResultBox)
				OverlayPortal:Send{"YFlip", Parameters.Length}
				ResultBox:Send{true}
			end;
			CostFunction = function(Parameters)
				return Parameters.Length ^ 2 * 100
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
			Description = "Flips the Y axis";
		};
		gray = {
			Execute = function(Parameters, ResultBox)
				OverlayPortal:Send{"Gray", Parameters.Length}
				ResultBox:Send{true}
			end;
			CostFunction = function(Parameters)
				return math.floor(Parameters.Length ^ 1.5 * 100)
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
			Description = "Converts the screen to grayscale";
		};
		dither = {
			Execute = function(Parameters, ResultBox)
				OverlayPortal:Send{"Dither", Parameters.Length}
				ResultBox:Send{true}
			end;
			CostFunction = function(Parameters)
				return math.floor(Parameters.Length ^ 1.5 * 100)
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
			Description = "Add grayscale dithering to the screen";
		};
		warp = {
			Execute = function(Parameters, ResultBox)
				OverlayPortal:Send{
					"Warp", {
						Length = Parameters.Length;
						Speed = Parameters.Speed;
						Strength = Parameters.Strength;
						Octaves = Parameters.Octaves;
					}
				}
				ResultBox:Send{true}
			end;
			CostFunction = function(Parameters)
				return Parameters.Length * Parameters.Speed * Parameters.Strength * Parameters.Octaves * 100
			end;
			Parameters = {
				Length = Type("integer", {Minimum=1});
				Speed = Type("integer", {Minimum=1});
				Strength = Type("integer", {Minimum=1});
				Octaves = Type("integer", {Minimum=1, Maximum=1});
			};
			Defaults = {
				Length = 5;
				Speed = 5;
				Strength = 5;
				Octaves = 4;
			};
			Grammar = P.Sequence{
				P.Group(P.Variable.Canonical"Integer", "Length");
				P.Atleast(1, P.Pattern" ");
				P.Group(P.Variable.Canonical"Integer", "Speed");
				P.Atleast(1, P.Pattern" ");
				P.Group(P.Variable.Canonical"Integer", "Strength");
				P.Atleast(1, P.Pattern" ");
				P.Group(P.Variable.Canonical"Integer", "Octaves");
			};
			Description = "Warps the screen";
		};
	}; SharedData.Shenanigans = Shenanigans; return Shenanigans
end; return GenerateShenanigans
