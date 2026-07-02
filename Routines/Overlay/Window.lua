local ffi = require"ffi"

local GL = require"OverlayBot.Rendering.GL"
local X11 = require"X11"
local XRender = require"XRender"

local Window; Window = {
	FindConfig = function(Display, Screen, LuaFBAttributes, RequireAlphaMask)
		local FBAttributes = ffi.new("int[?]", #LuaFBAttributes, LuaFBAttributes)

		local ConfigCount = ffi.new"int[1]"
		local FBConfigs = GL.Lib.glXChooseFBConfig(Display, Screen, FBAttributes, ConfigCount)
		ConfigCount = ConfigCount[0]
		
		for Index = 0, ConfigCount - 1 do
			local CFBConfig = FBConfigs[Index]
			local CVisualInfo = GL.Lib.glXGetVisualFromFBConfig(Display, CFBConfig)
			
			local PictFormat = XRender.XRenderFindVisualFormat(Display, CVisualInfo.visual)
			if PictFormat then
				if (not RequireAlphaMask) or (PictFormat.direct.alphaMask > 0) then
					return true, CFBConfig, CVisualInfo
				end
			end
		end

		return false, "Couldn't find suitable FBConfig"
	end;
	
	Create = function(Display, Root, VisualInfo, Width, Height, AttributesMask, Attributes)
		local WindowAttributes = ffi.new("XSetWindowAttributes", Attributes)
		
		local XWindow = X11.XCreateWindow(
			Display, Root, 
			0, 0, Width, Height, 
			0, 
			VisualInfo.depth, 
			X11.InputOutput, VisualInfo.visual, 
			AttributesMask, WindowAttributes
		)
		
		return XWindow
	end;
}; return Window
