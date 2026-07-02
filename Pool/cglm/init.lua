local ffi = require"ffi"
local cglm = require"cglm.FFI"
local Vector3Pool = require"OverlayBot.Pool.cglm.Vector3"
local Vector4Pool = require"OverlayBot.Pool.cglm.Vector4"
local Matrix4Pool = require"OverlayBot.Pool.cglm.Matrix4"

local OOP = require"Moonrise.OOP"

---@class OverlayBot.Pool.cglm
---@field Vector3Pool OverlayBot.Pool.cglm.Vector3Pool
---@field Vector4Pool OverlayBot.Pool.cglm.Vector4Pool
---@field Matrix4Pool OverlayBot.Pool.cglm.Matrix4Pool
---@overload fun(): OverlayBot.Pool.cglm
local cglmPool = OOP.Declarator.Shortcuts"OverlayBot.Pool.cglm"

function cglmPool:Initialize(Instance)
	Instance.Vector3Pool = Vector3Pool()
	Instance.Vector4Pool = Vector4Pool()
	Instance.Matrix4Pool = Matrix4Pool()
end

---@param Type "Vector3" | "Vector4" | "Matrix4"
function cglmPool:Obtain(Type)
	if Type == "Vector3" then
		return self.Vector3Pool:Obtain()
	elseif Type == "Vector4" then
		return self.Vector4Pool:Obtain()
	elseif Type == "Matrix4" then
		return self.Matrix4Pool:Obtain()
	end
end

function cglmPool:Reference(What)
	if ffi.istype("Vector3", What) then
		self.Vector3Pool:Reference(What)
	elseif ffi.istype("Vector4", What) then
		self.Vector4Pool:Reference(What)
	elseif ffi.istype("Matrix4", What) then
		self.Matrix4Pool:Reference(What) 
	end
end

function cglmPool:Release(What)
	if ffi.istype("Vector3", What) then
		self.Vector3Pool:Release(What)
	elseif ffi.istype("Vector4", What) then
		self.Vector4Pool:Release(What)
	elseif ffi.istype("Matrix4", What) then
		self.Matrix4Pool:Release(What) 
	end
end

function cglmPool:Add(LHS, RHS)
	local Result
	if ffi.istype("Vector4", LHS) then
		if ffi.istype("Vector4", RHS) then
			Result = self:Obtain"Vector4"
			cglm.glmc_vec4_add(LHS.Data, RHS.Data, Result.Data)
		elseif type(RHS) == "number" then
			Result = self:Obtain"Vector4"
			cglm.glmc_vec4_adds(LHS.Data, RHS, Result.Data)
		end
	elseif type(RHS) == "number" then
		Result = self:Add(RHS, LHS)
	end
	return Result
end

function cglmPool:Subtract(LHS, RHS)
	local Result
	if ffi.istype("Vector4", LHS) then
		if ffi.istype("Vector4", RHS) then
			Result = self:Obtain"Vector4"
			cglm.glmc_vec4_sub(LHS.Data, RHS.Data, Result.Data)
		elseif type(RHS) == "number" then
			Result = self:Obtain"Vector4"
			cglm.glmc_vec4_subs(LHS.Data, RHS, Result.Data)
		end
	elseif type(RHS) == "number" then
		Result = self:Subtract(RHS, LHS)
	end
	return Result
end

function cglmPool:Multiply(LHS, RHS)
	local Result
	if ffi.istype("Matrix4", LHS) then
		if ffi.istype("Matrix4", RHS) then
			Result = self:Obtain"Matrix4"
			cglm.glmc_mat4_mul(LHS.Data, RHS.Data, Result.Data)
		elseif ffi.istype("Vector4", RHS) then
			Result = self:Obtain"Vector4"
			cglm.glmc_mat4_mulv(LHS.Data, RHS.Data, Result.Data)
		else
			error"Not Implemented"
		end
	elseif ffi.istype("Vector4", LHS) then
		if ffi.istype("Vector4", RHS) then
			Result = self:Obtain"Vector4"
			cglm.glmc_vec4_mul(LHS.Data, RHS.Data, Result.Data)
		end
	end
	return Result
end

function cglmPool:Inverse(Of)
	local Result = self:Obtain"Matrix4"
	cglm.glmc_mat4_inv(Of.Data, Result.Data)
	return Result
end

return cglmPool
