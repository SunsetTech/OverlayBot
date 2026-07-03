local Chatter = require"Chatter"
local lpeg = require"lpeg"
local cqueues = require"cqueues"
local OOPEG = require"OOPEG"
local P = OOPEG.Nested.PEG
--local OBS = require"OBS"
return function(SharedData)
	local Basic; Basic = {
		--[[videolist = {
			Execute = function(Connection, Event, Parameters)
				local OBSConnection = OBS.Connection(
					"192.168.1.69", 
					SharedData.Config.OBS.Password, 
					SharedData.Config.OBS.Port
				)
				local SourcesResponseData = OBSConnection:Request(
					"GetSceneItemList", {
						sceneName = "Green Screen Memes";
					}
				)
				local SourceNames = {}
				for _, Item in pairs(SourcesResponseData.sceneItems) do
					if (Item.inputKind == "ffmpeg_source") then
						table.insert(SourceNames, Item.sourceName)
					end
				end
				Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "Videos: ".. table.concat(SourceNames, ", ")))
			end;
			Help = "Lists videos for use with ?video";
		};]]
		commandcost = {
			Execute = function(Connection, Event, Parameters)
				if not Parameters.Execution then
					Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "This command requires a parameter"))
				end
				local CommandString = Parameters.Execution
				local Execute, ExecParameters, CostFunction = lpeg.match(SharedData.CompiledCommandsGrammar, CommandString)
				if not Execute then
					Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "Command not found or syntax error"))
				else
					if CostFunction then
						local RequiredPoints = CostFunction(ExecParameters)
						Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "Execution requires ".. RequiredPoints .." Shenanigans Points"))
					else
						Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "Execution is free"))
					end
				end
			end;
			Help = "Calculates points required for shenanigan";
			Grammar = P.Group(P.Variable.Canonical"Trailing", "Execution");
		};
		credit = {
			Execute = function(Connection, Event, Parameters)
				if (Event.Prefix.Nick == "bigtrashking") then
					local UserID = SharedData.UserIDMap[Parameters.User:lower()]
					if UserID then
						local NewTotal = SharedData.Database:AddPoints(UserID, Parameters.Amount)
						Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "@".. Parameters.User .." You now have ".. NewTotal .." Shenanigans points."))
					else
						Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "User's id is not mapped"))
					end
				end
			end;
			Grammar = P.Sequence{
				P.Group(P.Variable.Canonical"Word", "User"),
				P.Atleast(1, P.Pattern" "),
				P.Group(P.Variable.Canonical"Integer", "Amount")
			};
			Help = "You must be the trashking to use this";
		};
		balance = {
			Execute = function(Connection, Event, _)
				local UserID = tonumber(Event.Tags["user-id"])
				assert(UserID)
				local Total = SharedData.Database:GetPoints(UserID)
				Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "@".. Event.Prefix.Nick .." You have ".. Total .." Shenanigans points."))
			end;
			Help = "Shows your Shenanigans Points balance";
		};
		shenanigans = {
			Execute = function(Connection, Event)
				print"?"
				local CommandList = {}
				for Command, _ in pairs(SharedData.Shenanigans) do
					table.insert(CommandList, Command)
				end
				local Response = Chatter.Command.PRIVMSG(Event.Params[1], "Currently available shenanigans, type !help <command name> for more info: ".. table.concat(CommandList, ", "))
				print("Responding", Response)
				Connection:write(Response)
			end;
			Help = "Display a list of shenanigans";
		};
		mscommands = {
			Execute = function(Connection, Event)
				local CommandList = {}
				for Command, _ in pairs(Basic) do
					table.insert(CommandList, "!".. Command)
				end
				Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], table.concat(CommandList, ", ")))
			end;
			Help = "Display a list of commands";
		};
		help = {
			Execute = function(Connection, Event, Parameters)
				local Command = Parameters.Command
				if Basic[Command] then
					Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], Basic[Command].Help))
					if Basic[Command].Grammar then
						Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "Usage: !".. Command .." ".. tostring(Basic[Command].Grammar)))
					end
				elseif SharedData.Shenanigans[Command] then
					Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], SharedData.Shenanigans[Command].Help))
					if SharedData.Shenanigans[Command].Grammar then
						Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "Usage: ?".. Command .." ".. tostring(SharedData.Shenanigans[Command].Grammar)))
					end
				else
					Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "Command not found"))
				end
			end;
			Defaults = {
				Command = "help";
			};
			Help = "Displays help for a given command";
			Grammar = P.Group(P.Variable.Canonical"Word", "Command");
		};
		freespeak = {
			Execute = function(Connection, Event, Parameters)
				if SharedData.TTSCooledDown then
					SharedData.TTSCooledDown = false
					SharedData.ScamTTS = false
					SharedData.RoutinePool:wrap(
						function()
							cqueues.sleep(30)
							SharedData.TTSCooledDown = true
							Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "Espeak TTS has cooled down"))
						end
					)
					SharedData.RoutinePool:wrap(
						function()
							cqueues.sleep(5)
							if not SharedData.ScamTTS then
								local espeak = io.popen("espeak", "w")
								assert(espeak)
								espeak:write(Parameters.Message)
								espeak:close()
							end
						end
					)
					local Chime = io.popen("vlc -I dummy /home/operator/Home/StreamAssets/TTSNotification.mp3 --play-and-exit","r")
					assert(Chime)
					Chime:close()
				else
					Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "TTS not cooled down"))
				end
			end;
			Defaults = {
				Message = "I forgot to enter a message";
			};
			Help = "free espeak tts. 5s delay. 30s cooldown.";
			Grammar = P.Group(P.Variable.Canonical"Trailing", "Message");
		};
		scam = {
			Execute = function(Connection, Event)
				if Event.Prefix.Host[1] == "bigtrashking" then
					SharedData.ScamTTS = true
					Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "Scamming queued TTS, if any"))
				else
					Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "You aren't me and cannot use this command"))
				end
			end;
			Help = "Scam the currently queued TTS, you must be BigTrashKing to use this";
		};
		toggleoverlay = {
			Execute = function(Connection, Event)
				if Event.Prefix.Host[1] == "bigtrashking" then
					SharedData.RenderOverlay = not SharedData.RenderOverlay
					Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "Overlay is now ".. (SharedData.RenderOverlay and "on" or "off") .."."))
				else
					Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "You must be BigTrashKing to use this"))
				end
			end;
			Help = "Toggle the overlay on and off. Only the broadcaster may use this"
		}
	}; SharedData.Basic = Basic; return Basic
end
