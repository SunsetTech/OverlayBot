local ffi = require"ffi"
local Vector3 = require"OverlayBot.Math.cglm.Vector3"
local OOP = require"Moonrise.OOP"

---@class OverlayBot.Pool.cglm.Vector3Pool: OverlayBot.Pool.CData
---@overload fun(): OverlayBot.Pool.cglm.Vector3Pool
---@diagnostic disable-next-line: assign-type-mismatch
local Vector3Pool = OOP.Declarator.Shortcuts(
	"OverlayBot.Pool.cglm.Vector3", {
		require"OverlayBot.Pool.CData"
	}
)

function Vector3Pool:Create()
	return Vector3()
end

function Vector3Pool:Prepare(Instance)
	ffi.fill(Instance.Data, ffi.sizeof"vec3")
end

---@return OverlayBot.Math.cglm.Vector3
function Vector3Pool:Obtain()
	---@diagnostic disable-next-line:undefined-field
	return Vector3Pool.Parents.CData.Obtain(self)
end

return Vector3Pool
