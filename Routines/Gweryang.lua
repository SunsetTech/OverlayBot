---@diagnostic disable:trailing-space
local Linux = require"Moonrise.System.Platform.Linux"
local Stream = require"Moonrise.Stream"
local Adapt = require"Moonrise.Adapt"
local Transform = Adapt.Transform
local AST = require"Moonrise.AST"

local Types = AST.Registry"OverlayBot.Gweryang"

---@param FromPath string
---@param ToPath string
local function Normalize(FromPath, ToPath)
	print("Normalize", FromPath, ToPath)
	local P, I, O, E = Linux.Spawn(
		"sox", {
			"--norm=0",
			FromPath, ToPath
		}
	)
	P:Close()
	I:Close()
	O:Close()
	E:Close()
end

---@param Path string
local function Play(Path)
	print("Play", Path)
	local P, I, O, E = Linux.Spawn(
		"pw-play", {
			"--target", "input.Gweryang";
			Path;
		}
	)
	P:Close()
	I:Close()
	O:Close()
	E:Close()
end

---@param Path string
local function Erase(Path)
	print("Erase", Path)
	local P, I, O, E = Linux.Spawn("rm", {Path})
	P:Close()
	I:Close()
	O:Close()
	E:Close()
end

local function Polly(Voice)
	return function(Message, OutputPath)
		print("Polly", Voice, Message, OutputPath)
		local P, I, O, E = Linux.Spawn(
			"aws", {
				"polly", "synthesize-speech";
				"--no-cli-pager";
				"--output-format", "mp3";
				"--voice-id", Voice;
				"--text", Message;
				OutputPath;
			}
		)
		P:Close()
		I:Close()
		E:Close()
		-- TODO: Check the output to ensure the request succeeded
		O:Close()
	end
end

local Voices = {
	{"brian", Polly"Brian"};
	{"joanna", Polly"Joanna"};
}

local Names = {}
local Generators = {}

for _, Voice in pairs(Voices) do
	local Name, Generator = Voice[1], Voice[2]
	table.insert(Names, Name)
	Generators[Name] = Generator
end

local Grammar = Transform.Grammar{
	Name = Transform.Set(Names);
	Speaker = Transform.Sequence{
		Transform.String"[", 
		Transform.Jump"Name" / AST.Lenses.Named"Name", 
		Transform.String"]"
	} / Types:Lens"Speaker";
	Message = Transform.All(
		Transform.Without(
			Transform.Jump"Speaker", 
			Transform.Bytes(1)
		)
	) / AST.Lenses.Flat;
	Dialogue = Transform.Sequence{
		Transform.Jump"Speaker" / AST.Lenses.Named"Speaker";
		Transform.Jump"Message" / AST.Lenses.Named"Message";
	} / Types:Lens"Dialogue";
	Parts = Transform.All(Transform.Jump"Dialogue");
	Transform.Jump"Parts";
}

---@param Request string
local function Parse(Request)
	return Adapt.Process(Grammar, "Raise", Stream.String(Request))
end

---@param RequestBox Heartstrings.Mailbox
local function Main(RequestBox, CachePath)
	print"Gweryang starting up"
	while true do
		local Requests = RequestBox:Wait()
		for _, Request in ipairs(Requests) do
			print("Processing", Request)
			---@cast Request string
			local Success, Parts = Parse(Request)
			if not Success or #Parts == 0 then
				print"parse failed. TODO: inform invoker and refund their points"
			end
			print(#Parts, table.unpack(Parts))
			local Clips = {}
			for _, Part in ipairs(Parts) do
				local Voice = Part:GetElement"Speaker":GetElement"Name":lower()
				local Message = Part:GetElement"Message"
				local OutputPath = CachePath .."/".. tostring(#Clips + 1) ..".mp3"
				print("Generating", Voice, Message, OutputPath)
				Generators[Voice](Message, OutputPath)
				local NormalizedPath = OutputPath ..".normalized.mp3"
				Normalize(OutputPath, NormalizedPath)
				Erase(OutputPath)
				table.insert(Clips, NormalizedPath)
			end
			for _, Clip in pairs(Clips) do
				Play(Clip)
				Erase(Clip)
			end
		end
	end
end; return Main
