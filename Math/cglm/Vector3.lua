local ffi = require"ffi"
local cglm = require"cglm.FFI"
local OOP = require"Moonrise.OOP"

ffi.cdef[[
	typedef struct {
		vec3 Data;
	} Vector3;
]]

---@class OverlayBot.Math.cglm.Vector3
---@field Data number[]
---@diagnostic disable-next-line: assign-type-mismatch
local Vector3 = OOP.Declarator.Shortcuts"OverlayBot.Math.cglm.Vector3"

function Vector3:__instantiate()
	local Instance = self.__metatype()
	local ID = tostring(Instance)

	self:__register(Instance, ID)
	self:__initialize(Instance)
	return Instance
end;

function Vector3:Initialize(Instance)
	ffi.fill(Instance.Data, ffi.sizeof"vec3")
end

function Vector3:Get(Index)
	return self.Data[Index]
end

function Vector3:Set(Index, Value)
	self.Data[Index] = Value
end

function Vector3:Magnitude()
	return cglm.glmc_vec3_norm(self.Data)
end

function Vector3:Normalize()
	cglm.glmc_vec3_normalize(self.Data)
end

function Vector3:NormalizeTo(Where)
	cglm.glmc_vec3_normalize_to(self.Data, Where.Data)
end

function Vector3:Distance(To)
	return cglm.glmc_vec3_distance(self.Data, To.Data)
end

Vector3.__metatype = ffi.metatype("Vector3", Vector3)

return Vector3
