local ffi = require"ffi"
local cglm = require"cglm.FFI"
local OOP = require"Moonrise.OOP"

ffi.cdef[[
	typedef struct {
		mat4 Data;
	} Matrix4;
]]

---@class OverlayBot.Math.cglm.Matrix4
---@field Data number[]
---@diagnostic disable-next-line: assign-type-mismatch
local Matrix4 = OOP.Declarator.Shortcuts"OverlayBot.Math.cglm.Matrix4"

function Matrix4:__instantiate()
	local Instance = self.__metatype()
	local ID = tostring(Instance)

	self:__register(Instance, ID)
	self:__initialize(Instance)
	return Instance
end;

function Matrix4:Initialize(Instance)
	ffi.fill(Instance.Data, ffi.sizeof"mat4")
end

function Matrix4:Get(Column, Row)
	return self.Data[Column][Row]
end

function Matrix4:Set(Column, Row, Value)
	self.Data[Column][Row] = Value
end

function Matrix4:MakePerspective(FOV, Aspect, Near, Far)
	cglm.glmc_perspective(FOV, Aspect, Near, Far, self.Data)
end

function Matrix4:MakeTranslation(Translation)
	cglm.glmc_translate_make(self.Data, Translation.Data)
end

function Matrix4:MakeScale(By)
	cglm.glmc_scale_make(self.Data, By.Data)
end

function Matrix4:InvertInto(Destination)
	cglm.glmc_mat4_inv(self.Data, Destination.Data)
end

function Matrix4:Rotate(Angle, Axis)
	cglm.glmc_rotate(self.Data, Angle, Axis.Data)
end

function Matrix4:Scale(By)
	cglm.glmc_scale(self.Data, By.Data)
end

function Matrix4:Translate(By)
	cglm.glmc_translate(self.Data, By.Data)
end

Matrix4.__metatype = ffi.metatype("Matrix4", Matrix4)

return Matrix4
