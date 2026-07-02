local cqueues = require"cqueues"
local websocket = require"http.websocket"
local dkjson = require"dkjson"

---@param Address string
---@param AuthToken string
---@param Database unknown
---@param AdminID string
---@param Shenanigans table<string, OverlayBot.Commands.Shenanigans.Definition>
local function Main(Address, AuthToken, Database, AdminID, Shenanigans)
	while true do 
		local Client = websocket.new_from_uri(Address)
		local Success, Error = Client:connect()
		if Success then
			print"Connected to overlaybot-web-server"
			while true do
				::continue::
				local Frame = Client:receive()
				print("WebClient receive()", Frame)
				if not Frame then
					goto retry
				end
				Frame = dkjson.decode(Frame)
				if Frame.Type == "Challenge" then
					print"Received challenge"
					local Response = {
						Type = "Authorization";
						Token = AuthToken;
					}
					Response = dkjson.encode(Response)
					Client:send(Response)
				elseif Frame.Type == "Introspect" then
					local Controls = {}
					for Name, Definition in pairs(Shenanigans) do
						Controls[Name] = {
							Parameters = Definition.Parameters;
							Defaults = Definition.Defaults;
						}
					end
					local Response = {
						Type = "Introspection";
						Controls = Controls;
					}
					Response = dkjson.encode(Response)
					Client:send(Response)
				elseif Frame.Type == "Activate" then
					local Shenanigan = Shenanigans[Frame.Command]
					local RequiredPoints = 0
					if (Frame.TwitchID ~= AdminID) then
						RequiredPoints = Shenanigan.CostFunction(Frame.Parameters)
						local Total = Database:GetPoints(Frame.TwitchID)
						if RequiredPoints > Total then
							local RejectedMessage = {
								Type = "Rejected";
								Reason = "not enough points";
								ConnectionID = Frame.ConnectionID;
								RequestID = Frame.RequestID;
							}
							Client:send(dkjson.encode(RejectedMessage))
							goto continue
						end
					end
					Success, Error = Shenanigan.Execute(Frame.Parameters)
					if not Success then
						local RejectedMessage = {
							Type = "Rejected";
							Reason = Error;
							ConnectionID = Frame.ConnectionID;
							RequestID = Frame.RequestID;
						}
						Client:send(dkjson.encode(RejectedMessage))
					else
						Database:AddPoints(Frame.TwitchID, -RequiredPoints)
						local ActivatedMessage = {
							Type = "Activated";
							ConnectionID = Frame.ConnectionID;
							RequestID = Frame.RequestID;
						}
						Client:send(dkjson.encode(ActivatedMessage))
					end
				end
			end
		else
			print"Couldn't connect to overlaybot-web-server"
			print(Error)
		end
		::retry::
		cqueues.sleep(5)
	end
end

return Main
