local OOP = require"Moonrise.OOP"
local Frame = require"OverlayBot.Image.Animated.Frame"

local Animated = OOP.Declarator.Shortcuts"OverlayBot.Image.Animated"

function Animated:Initialize(Instance, Width, Height)
	Instance.Frames = {}
	Instance.Width = Width
	Instance.Height = Height
end

function Animated:AddFrame(Data, Timestamp)
	table.insert(self.Frames, Frame(Data, Timestamp))
end

return Animated
