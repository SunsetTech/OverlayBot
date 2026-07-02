local websocket = require"http.websocket"
local dkjson = require"dkjson"
local lsha2 = require"lsha2"
local mime = require"mime"

local OOP = require"Moonrise.OOP"

local Connection = OOP.Declarator.Shortcuts"OverlayBot.Routines.Connection"

local function hexToBytes(hex)
    local bytes = {}
    for i = 1, #hex, 2 do
        local hexByte = string.sub(hex, i, i + 1)
        local byte = tonumber(hexByte, 16)
        table.insert(bytes, string.char(byte))
    end
    return table.concat(bytes)
end

local function GenerateAuthResponse(Password, Salt, Challenge)
    local concat1 = Password .. Salt
    local hash1 = hexToBytes(lsha2.hash256(concat1))
    local base64_secret = mime.b64(hash1)
    local concat2 = base64_secret .. Challenge
    local hash2 = hexToBytes(lsha2.hash256(concat2))
    return mime.b64(hash2)
end

function Connection:Initialize(Instance, Address, Password, Port)
	Instance.Socket = websocket.new_from_uri("ws://".. Address ..":".. Port)
	Instance.Socket:connect()
	assert(Instance.Socket, "Could not connect to OBS")
	Instance.Tally = 0
	
	local ResponseObject = Instance:Receive()
	assert(ResponseObject)
	local ResponseData = ResponseObject.d
	local AuthData = ResponseData.authentication

	Instance:Send( 
		1, {
			rpcVersion = ResponseData.rpcVersion;
			authentication = GenerateAuthResponse(
				Password, 
				AuthData.salt, AuthData.challenge
			);
		}
	)
	
	--TODO validate connection was successful
	print(Instance:Receive())
end

function Connection:Receive()
	local Response,_ = self.Socket:receive()
	assert(Response)
	local Object = dkjson.decode(Response)
	return Object
end

function Connection:Send(Op, Data)
	self.Socket:send(
		dkjson.encode{
			op = Op;
			d = Data;
		}
	)
end

function Connection:Request(Type, Data)
	self.Tally = self.Tally + 1
	
	self:Send(
		6, {
			requestType = Type;
			requestId = self.Tally;
			requestData = Data;
		}
	)
	
	return self:Receive().d.responseData
end

return Connection
