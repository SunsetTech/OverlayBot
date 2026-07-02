-- TODO: this system is naively implemented and doesn't work well
local ffi = require"ffi"
local OOP = require"Moonrise.OOP"

---@class OverlayBot.Pool.CData
---
local CDataPool = OOP.Declarator.Shortcuts"OverlayBot.Pool.CData"

function CDataPool:Initialize(Instance)
	Instance.Pool = {}
	Instance.ReferenceCounts = setmetatable({},{__mode="k"})
	Instance.Finalizer = function(Object)
		Instance.ReferenceCounts[Object] = 1
		Instance:Release(Object)
	end
end

function CDataPool:Create()
	error"Must be implemented"
end

function CDataPool:Prepare(Object, ...)
	error"Must be implemented"
end

function CDataPool:Release(Object)
	self.ReferenceCounts[Object] = self.ReferenceCounts[Object] - 1
	if self.ReferenceCounts[Object] == 0 then
		ffi.gc(Object, nil)
		self.ReferenceCounts[Object] = nil
		table.insert(self.Pool, Object)
	end
end

function CDataPool:Reference(Object)
	self.ReferenceCounts[Object] = self.ReferenceCounts[Object] + 1
end

function CDataPool:Obtain(...)
	if #self.Pool == 0 then
		Object = self:Create()
	else
		Object = table.remove(self.Pool)
	end
	self.ReferenceCounts[Object] = 1
	self:Prepare(Object, ...)
	return ffi.gc(Object, self.Finalizer)
end

return CDataPool
