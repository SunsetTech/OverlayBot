local ffi = require"ffi"

local X11 = require"X11"
local Xcomposite = require"Xcomposite"
local GL = require"OverlayBot.Rendering.GL"

local Capture; Capture = {
	FindWindowByTitle = function(Title, Exclude)
		local xwininfo = io.popen(([[xwininfo -name "%s" | grep "Window id" | awk '{print $4}']]):format(Title), "r")
		assert(xwininfo)
		local StringID = xwininfo:read"a"
		print(StringID)
		xwininfo:close()
		if StringID and #StringID > 0 then
			return tonumber(StringID) or 0
		else
			return 0
		end
	end,

	FindCompatibleFBConfig = function(Display, Window) -- we should probably convert the error() calls into error returns
		local WindowAttributes = ffi.new("XWindowAttributes[1]")
		if X11.XGetWindowAttributes(Display, Window, WindowAttributes) == 0 then
			error("Failed to get window attributes")
		end
		WindowAttributes = WindowAttributes[0]
		local Depth = WindowAttributes.depth
		
		local Count = ffi.new("int[1]")
		local Configs = GL.Lib.glXChooseFBConfig(Display, X11.XDefaultScreen(Display), nil, Count)
		if Configs == nil then
			error("Failed to retrieve FBConfigs")
		end

		Count = Count[0]
		
		for Index = 0, Count - 1 do
			local VisualInfo = GL.Lib.glXGetVisualFromFBConfig(Display, Configs[Index])
			if VisualInfo.depth == Depth then --Compare by required bit depth because nothing else was working and it's probably fine. probably.
				return Configs[Index]
			end
		end

		error("No compatible FBConfig found for window visual ID")
	end,

	ObtainSurface = function(Display, Window)
		local Surface = {}
		print("Obtaining surface for", Window)
		Surface.Pixmap = Xcomposite.XCompositeNameWindowPixmap(Display, Window)

		local Width, Height, Unused = ffi.new"int[1]", ffi.new"int[1]", ffi.new"int[1]"
		local Root = ffi.new"Window[1]"
		X11.XGetGeometry(Display, Surface.Pixmap, Root, Unused, Unused, Width, Height, Unused, Unused)

		Surface.Width = Width[0]
		Surface.Height = Height[0]

		return Surface
	end,

	ReleaseSurface = function(Display, Surface)
		print("Releasing Pixmap", Display, Surface.Pixmap)
		X11.XFreePixmap(Display, Surface.Pixmap)
	end,

	CreateGLXPixmap = function(Display, FBConfig, Surface, Attributes)
		print("Creating Pixmap", Display, FBConfig, Surface, Attributes)
		return GL.Lib.glXCreatePixmap(Display, FBConfig, Surface.Pixmap, Attributes)
	end,

	DestroyGLXPixmap = function(Display, Pixmap)
		print("Destroying Pixmap", Display, Pixmap)
		GL.Lib.glXDestroyPixmap(Display, Pixmap)
	end,

	CreateTexture = function()
		local TextureHandle = ffi.new"GLuint[1]"
		GL.API.GenTextures(1, TextureHandle)
		TextureHandle = TextureHandle[0]

		GL.API.BindTexture(GL.Lib.GL_TEXTURE_2D, TextureHandle)

		GL.API.TexParameteri(GL.Lib.GL_TEXTURE_2D, GL.Lib.GL_TEXTURE_MIN_FILTER, GL.Lib.GL_LINEAR)
		GL.API.TexParameteri(GL.Lib.GL_TEXTURE_2D, GL.Lib.GL_TEXTURE_MAG_FILTER, GL.Lib.GL_LINEAR)
		GL.API.TexEnvf(GL.Lib.GL_TEXTURE_ENV, GL.Lib.GL_TEXTURE_ENV_MODE, GL.Lib.GL_MODULATE)

		return {
			Handle = TextureHandle;
			Width = 0;
			Height = 0;
		}
	end,

	BindGLXPixmapToTexture = function(Display, Pixmap, Texture)
		GL.API.BindTexture(GL.Lib.GL_TEXTURE_2D, Texture.Handle)
		GL.Lib.glXBindTexImageEXT(Display, Pixmap, GL.Lib.GLX_FRONT_EXT, nil)
	end,

	UnbindGLXPixmapFromTexture = function(Display, Pixmap, Texture)
		Texture.Width = 0
		Texture.Height = 0

		GL.API.BindTexture(GL.Lib.GL_TEXTURE_2D, Texture.Handle)
		GL.Lib.glXReleaseTexImageEXT(Display, Pixmap, GL.Lib.GLX_FRONT_EXT)
	end,

	ObtainAndBind = function(Display, FBConfig, Window, PixmapAttributes, Texture)
		--if FBConfig == nil then
		print"Finding FBConfig"
			FBConfig = Capture.FindCompatibleFBConfig(Display, Window)
		--end

		local Surface = Capture.ObtainSurface(Display, Window)
		Surface.GLXPixmap = Capture.CreateGLXPixmap(Display, FBConfig, Surface, PixmapAttributes)
		Capture.BindGLXPixmapToTexture(Display, Surface.GLXPixmap, Texture)

		Texture.Width = Surface.Width
		Texture.Height = Surface.Height

		return Surface
	end,

	UnbindAndRelease = function(Display, Surface, Texture)
		Capture.UnbindGLXPixmapFromTexture(Display, Surface.GLXPixmap, Texture)
		Capture.DestroyGLXPixmap(Display, Surface.GLXPixmap)
		Capture.ReleaseSurface(Display, Surface)
	end,
}

return Capture

