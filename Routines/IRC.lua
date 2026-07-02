local cqueues = require"cqueues"
cqueues.errno = require"cqueues.errno"
cqueues.socket = require"cqueues.socket"
local lpeg = require"lpeg"
local IRCGrammar = require"Chatter.Grammar":Decompose():Decompose()
local Chatter = require"Chatter"

---@param Shared OverlayBot.SharedData
---@param Token Twinge.API.Token
---@param Username string
---@param Channel string
---@param RedeemID string
---@param CompiledCommandsGrammar userdata
local function Main(Shared, Token, Username, Channel, AdminID, RedeemID, CompiledCommandsGrammar)
	local Tries = 0
	repeat
		Tries = Tries + 1
		
		print"Connecting to Twitch IRC"
		local Output
		local Connection = cqueues.socket.connect("irc.chat.twitch.tv", 6697)
		if (not Connection:connect()) or (not Connection:starttls()) then
			print"Couldn't connect to Twitch IRC, retrying"
			goto retry
		end
		Tries = 0
		
		Connection:write("CAP REQ :twitch.tv/membership twitch.tv/commands twitch.tv/tags\r\n")
		Connection:write(("PASS oauth:%s\r\n"):format(Token.Access))
		Connection:write(("NICK %s\r\n"):format(Username))
		Connection:write(("JOIN #%s\r\n"):format(Channel))
		
		repeat
			Output, Error = Connection:read"*l"
			if (not Output) then
				---@type integer | boolean | nil
				local r
				---@type integer | boolean | nil
				local w
				r,w = Connection:error"rw"
				print("Connection:error()", cqueues.errno.strerror(r), cqueues.errno.strerror(w))
				r,w = Connection:eof()
				print("Connection:eof()", r, w)
				print"Connection to Twitch IRC failed, reconnecting"
				goto retry
			else
				print(Output)
				local Event = lpeg.match(IRCGrammar, Output)
				if (Event) then
					local Tags = {}
					
					if Event.Tags and type(Event.Tags) == "table" then
						for _, Tag in pairs(Event.Tags) do
							Tags[Tag.Key] = Tag.Value
						end
						Event.Tags = Tags
					end
					
					if Event.Prefix and Event.Prefix.Nick then
						Shared.UserIDMap[Event.Prefix.Nick:lower()] = Tags["user-id"]
					end
					
					local UserID = tonumber(Tags["user-id"])
					
					local RewardMessagePrefix, CommandPointsToCredit
					
					if (Tags.bits ~= nil) then
						local Bits = tonumber(Tags.bits)
						CommandPointsToCredit = Bits*690
						RewardMessagePrefix = "Thanks for the ".. Tags.bits .." bit(s)!"
					elseif (Tags["custom-reward-id"] == RedeemID) then
						CommandPointsToCredit = 1000
						RewardMessagePrefix = "Thanks for the redeem!"
					end
					
					if CommandPointsToCredit ~= nil then
						local NewTotal = Shared.Database:AddPoints(UserID, CommandPointsToCredit)
						Connection:write(
							Chatter.Command.PRIVMSG(
								"#".. Channel,
								("%s You have been credited %i Shenanigans Points! Your total is now %i"):format(
									RewardMessagePrefix, CommandPointsToCredit, NewTotal
								)
							)
						)
					end
					
					if (Event.Command == "PING") then
						Connection:write(("PONG :%s\r\n"):format(Event.Trailing))
					elseif (Event.Command == "PRIVMSG") then
						local CommandString = Event.Trailing
						local Execute, Parameters, CostFunction = lpeg.match(CompiledCommandsGrammar, CommandString)
						if Execute then
							if CostFunction and (UserID == AdminID) then
								local RequiredPoints = CostFunction(Parameters)
								local Total = Shared.Database:GetPoints(Tags["user-id"])
								if RequiredPoints > Total then
									Connection:write(Chatter.Command.PRIVMSG(Event.Params[1], "You dont have enough Shenanigans Points to do that"))
									goto continue
								end
								Shared.Database:AddPoints(Tags["user-id"], -RequiredPoints)
							end
							Execute(Parameters)
						end
					end
				end
			end
			::continue::
		until not Output
		::retry::
	until Tries == 5
end; return Main
