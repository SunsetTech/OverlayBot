local ffi = require"ffi"
local Matrix4 = require"OverlayBot.Math.cglm.Matrix4"
local OOP = require"Moonrise.OOP"

---@class OverlayBot.Pool.cglm.Matrix4Pool: OverlayBot.Pool.CData
---@overload fun(): OverlayBot.Pool.cglm.Matrix4Pool
---@diagnostic disable-next-line: assign-type-mismatch
local Matrix4Pool = OOP.Declarator.Shortcuts(
	"OverlayBot.Pool.cglm.Matrix4", {
		require"OverlayBot.Pool.CData"
	}
)

function Matrix4Pool:Create()
	return Matrix4()
end

function Matrix4Pool:Prepare(Instance)
	ffi.fill(Instance.Data, ffi.sizeof"mat4")
end

---@return OverlayBot.Math.cglm.Matrix4
function Matrix4Pool:Obtain()
	---@diagnostic disable-next-line:undefined-field
	return Matrix4Pool.Parents.CData.Obtain(self)
end

return Matrix4Pool
