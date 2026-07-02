local ffi = require"ffi"
local Vector4 = require"OverlayBot.Math.cglm.Vector4"
local OOP = require"Moonrise.OOP"

---@class OverlayBot.Pool.cglm.Vector4Pool: OverlayBot.Pool.CData
---@overload fun(): OverlayBot.Pool.cglm.Vector4Pool
---@diagnostic disable-next-line: assign-type-mismatch
local Vector4Pool = OOP.Declarator.Shortcuts(
	"OverlayBot.Pool.cglm.Vector4", {
		require"OverlayBot.Pool.CData"
	}
)

function Vector4Pool:Create()
	return Vector4()
end

function Vector4Pool:Prepare(Instance)
	ffi.fill(Instance.Data, ffi.sizeof"vec4")
end

---@return OverlayBot.Math.cglm.Vector4
function Vector4Pool:Obtain()
	---@diagnostic disable-next-line:undefined-field
	return Vector4Pool.Parents.CData.Obtain(self)
end

return Vector4Pool
