local ffi = require"ffi"
local cglm=require"cglm.FFI"
local OOP = require"Moonrise.OOP"

ffi.cdef[[
	typedef struct {
		vec4 Data;
	} Vector4;
]]

---@class OverlayBot.Math.cglm.Vector4
---@field Data number[]
---@diagnostic disable-next-line: assign-type-mismatch
local Vector4 = OOP.Declarator.Shortcuts"OverlayBot.Math.cglm.Vector4"

function Vector4:__instantiate()
	local Instance = self.__metatype()
	local ID = tostring(Instance)

	self:__register(Instance, ID)
	self:__initialize(Instance)
	return Instance
end;

function Vector4:Initialize(Instance)
	ffi.fill(Instance.Data, ffi.sizeof"vec4")
end

function Vector4:Get(Index)
	return self.Data[Index]
end

function Vector4:Set(Index, Value)
	self.Data[Index] = Value
end

function Vector4:Magnitude()
	return cglm.glmc_vec4_norm(self.Data)
end

function Vector4:Normalize()
	cglm.glmc_vec4_normalize(self.Data)
end

function Vector4:NormalizeTo(Where)
	cglm.glmc_vec4_normalize_to(self.Data, Where.Data)
end

function Vector4:Distance(To)
	return cglm.glmc_vec4_distance(self.Data, To.Data)
end

Vector4.__metatype = ffi.metatype("Vector4", Vector4)

return Vector4
