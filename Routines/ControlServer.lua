---@diagnostic disable: trailing-space
local cqueues = require"cqueues"
local dkjson = require"dkjson"
local Heartstrings = require"Moonrise.Heartstrings"
local Stream = require"Moonrise.Stream"
local Tools = require"Moonrise.Tools"

---@param Port integer
---@param OverlayPortal Heartstrings.Mailbox
local function Main(Port, OverlayPortal)
	local Server = Heartstrings.TCP()
	assert(Server:Bind("127.0.0.1", Port) == 0, "Couldn't bind to address")
	local ClientPool = cqueues.new()
	Server:Listen(
		4, function(Error)
			assert(Error == nil, Error)
			local Client = Heartstrings.TCP()
			print("Connected", Server, Client)
			Server:Accept(Client)
			local ClientIO = Stream.Buffered(Client)
			ClientPool:wrap(
				function()
					local Message, Stop
					repeat
						Message, Stop = Tools.Stream.Read.Line(ClientIO)
						print("Client", Message, Stop)
						if Message and Message ~= "" then
							Message = dkjson.decode(Message)
							if Message.Command == "Overlay.Hide" then
								if Message.State then
									OverlayPortal:Send{"Hide", true}
								else
									OverlayPortal:Send{"Hide", false}
								end
							end
						end
					until Message == "" or Stop
				end
			)
		end
	)
	while true do
		local Success, Error, _, Thread = ClientPool:step()
		if not Success then
			print("Error", debug.traceback(Thread))
			error(Error)
		end
	end
end

return Main
