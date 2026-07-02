local OOP = require"Moonrise.OOP"

local Frame = OOP.Declarator.Shortcuts"OverlayBot.Image.Animated.Frame"

function Frame:Initialize(Instance, Data, Timestamp)
	Instance.Data = Data
	Instance.Timestamp = Timestamp
end

return Frame

