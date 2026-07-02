--- TODO: retarget this to work on the system asset directory
local TwitchConfig = require"TwitchConfig" -- TODO: fix to use the new config location system
local dkjson = require"dkjson"
local lfs = require"lfs"
local http = {
	request = require"http.request";
}

local function Retrieve(URI)
	local Request = http.request.new_from_uri(URI)
	local ResponseHeaders, ResponseStream = Request:go()
	if ResponseHeaders then
		return ResponseStream:get_body_as_string()
	end
end

local Request = http.request.new_from_uri(("https://7tv.io/v3/users/twitch/%s"):format(TwitchConfig.ID))

local ResponseHeaders, ResponseStream = Request:go()
assert(ResponseHeaders and ResponseStream)
local ResponseBody = ResponseStream:get_body_as_string()
local ResponseObject = dkjson.decode(ResponseBody)
assert(ResponseObject)
print(#ResponseObject.emote_set.emotes, "emotes in set")
lfs.mkdir"Assets/Emotes/7TV"
for _, EmoteData in pairs(ResponseObject.emote_set.emotes) do
	print(EmoteData.name)
	print(#EmoteData.data.host.files, " associated files")
	local Host = EmoteData.data.host.url
	local Path = ("http:%s/4x.webp"):format(Host)
	print(Path)
	local EmoteFileContents = Retrieve(Path)
	assert(EmoteFileContents)
	local OutputFile = io.open(("Assets/Emotes/7TV/%s.webp"):format(EmoteData.name), "wb")
	assert(OutputFile)
	OutputFile:write(EmoteFileContents)
	OutputFile:close()
end
--print(ResponseBody)
