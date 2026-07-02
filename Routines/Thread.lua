---@diagnostic disable:trailing-space

local function Main(Required, Body, ...)
	local Arguments = {...}
	
	local lanes = require"lanes"
	local Portal = require"Moonrise.Heartstrings.Portal"
	local CompletionPortal = Portal(lanes.linda())
	lanes.gen(
		"*", {
			required = Required;
		},
		function()
			table.unpack = table.unpack or unpack
			unpack = unpack or table.unpack
			local Results = {
				xpcall(
					function() Body(table.unpack(Arguments)) end,
					debug.traceback
				)
			}
			print(table.unpack(Results))
			CompletionPortal:Send(Results)
		end
	)()
	print("Thread exit", table.unpack(CompletionPortal:Receive()))
end
return Main
