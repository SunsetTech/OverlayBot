---@diagnostic disable:trailing-space
local bit = require"bit"
local ffi = require"ffi"

local cqueues = require"cqueues"

local X11 = require"X11"
local Xcomposite = require"Xcomposite"
local Xfixes = require"Xfixes"

local libndi = require"libndi"

local Rendering = require"OverlayBot.Rendering"
local GL = Rendering.GL
local Utils = require"OverlayBot.Utils"

local Capture = require"OverlayBot.Routines.Overlay.Capture"
local Assets = require"OverlayBot.Routines.Overlay.Assets"
local Context = require"OverlayBot.Routines.Overlay.Context"
local NDI = require"OverlayBot.Routines.Overlay.NDI"
local Window = require"OverlayBot.Routines.Overlay.Window"
local Renderer = require"OverlayBot.Routines.Overlay.Renderer"

local function GetMousePosition(Display, Root)
	local RootReturn = ffi.new"Window[1]"
	local ChildReturn = ffi.new"Window[1]"
	local RootX = ffi.new"int32_t[1]"
	local RootY = ffi.new"int32_t[1]"
	local WindowX = ffi.new"int32_t[1]"
	local WindowY = ffi.new"int32_t[1]"
	local MaskReturn = ffi.new"uint32_t[1]"
	if X11.XQueryPointer(Display, Root, RootReturn, ChildReturn, RootX, RootY, WindowX, WindowY, MaskReturn) == 1 then
		return true, RootX[0], RootY[0]
	end
	return false, 0, 0
end

---@param Shared OverlayBot.Routines.Overlay.Shared
local function Main(Shared)
	print"Initializing NDI library"
	NDI.Initialize()
	
	print"Creating NDI finder"
	local Finder = NDI.CreateFinder{
		show_local_sources = 1;
		p_groups = nil;
		p_extra_ips = nil;
	}
	 
	print"Waiting for NDI source"
	local Source = NDI.WaitForSource(Finder, "STORM (OBS-Overlays)")
	local Receiver = NDI.CreateReceiver{
		source_to_connect_to = Source;
		color_format = libndi.Library.NDIlib_recv_color_format_RGBX_RGBA;
		bandwidth = libndi.Library.NDIlib_recv_bandwidth_highest;
		allow_video_fields = false;
		p_ndi_recv_name = nil;
	}
	
	local Synchronizer = NDI.CreateSynchronizer(Receiver)
	
	local Display = X11.XOpenDisplay(nil)
	assert(Display, "Couldn't open display")
	
	local Screen = X11.XDefaultScreen(Display)
	local Root = X11.XDefaultRootWindow(Display)

	local LuaFBAttributes = {
		GL.Lib.GLX_BIND_TO_TEXTURE_RGBA_EXT   ; true                                                ;
		GL.Lib.GLX_DRAWABLE_TYPE              ; bit.bor(GL.Lib.GLX_PIXMAP_BIT,GL.Lib.GLX_WINDOW_BIT);
		GL.Lib.GLX_BIND_TO_TEXTURE_TARGETS_EXT; GL.Lib.GLX_TEXTURE_2D_BIT_EXT                       ;
		GL.Lib.GLX_RENDER_TYPE                ; GL.Lib.GLX_RGBA_BIT                                 ;
		GL.Lib.GLX_RED_SIZE                   ; 4                                                   ;
		GL.Lib.GLX_GREEN_SIZE                 ; 4                                                   ;
		GL.Lib.GLX_BLUE_SIZE                  ; 4                                                   ;
		GL.Lib.GLX_ALPHA_SIZE                 ; 4                                                   ;
		GL.Lib.GLX_DOUBLEBUFFER               ; true                                                ;
		0;
	}
	local FoundFBConfig, FBConfigOrError, VisualInfo = Window.FindConfig(Display, Screen, LuaFBAttributes, true)
	assert(FoundFBConfig and VisualInfo, FBConfigOrError)
	local FBConfig = FBConfigOrError
	
	local Colormap = X11.XCreateColormap(Display, Root, VisualInfo.visual, 0);
	local XWindow = Window.Create(
		Display, Root, VisualInfo, 
		1920, 1080,
		bit.bor(X11.CWColormap, X11.CWBorderPixel, X11.CWOverrideRedirect), {
			event_mask = bit.bor(X11.ExposureMask, X11.KeyPressMask);
			colormap = Colormap; 
			border_pixel = 0;
			override_redirect = true;
		}
	)

	local XRegion = Xfixes.XFixesCreateRegion(Display, 0, 0)
	Xfixes.XFixesSetWindowShapeRegion(Display, XWindow, Xfixes.ShapeBounding, 0, 0, 0)
	Xfixes.XFixesSetWindowShapeRegion(Display, XWindow, Xfixes.ShapeInput, 0, 0, XRegion)
	
	Xfixes.XFixesDestroyRegion(Display, XRegion)
	X11.XMapWindow(Display, XWindow)

	local GLWindow = GL.Lib.glXCreateWindow(Display, FBConfig, XWindow, nil)

	local GLContext = GL.Lib.glXCreateNewContext(Display, FBConfig, GL.Lib.GLX_RGBA_TYPE, nil, 1)
	assert(GLContext, "Couldn't create OpenGL context")

	GL.Lib.glXMakeContextCurrent(Display, GLWindow, GLWindow, GLContext)
	Context.Setup()

	print"Loading textures"
	local Start = Utils.GetTime()
	local Textures, TotalTextures = Assets.LoadTextures()
	print("Loaded ".. TotalTextures .." textures")
	
	print"Creating dynamic textures"
	local GamePixmapAttributes = ffi.new(
		"const int[5]", {
			GL.Lib.GLX_TEXTURE_TARGET_EXT, GL.Lib.GLX_TEXTURE_2D_EXT,
			GL.Lib.GLX_TEXTURE_FORMAT_EXT, GL.Lib.GLX_TEXTURE_FORMAT_RGB_EXT,
			0
		}
	)
	Textures.Game = Capture.CreateTexture()
	Textures.NDISource = NDI.CreateTexture()
	print("Texture loading/creation took ".. Utils.GetTime() - Start .." seconds")
	Shared.Textures = Textures.Buddies
	
	local RendererInstance = Renderer(1920, 1080)
	local LastUpdate = Utils.GetTime()
	local Event = ffi.new"XEvent[1]"
	local GameWindowMapped = false
	local GameSurface
	local GameWindow
	local CursorHidden = false
	while true do
		local CurrentTime = Utils.GetTime()
		local Delta = CurrentTime - LastUpdate
		LastUpdate = CurrentTime

		local ShouldReobtainGameSurface = false
		while (X11.XPending(Display) > 0) do
			print("Pending Events", X11.XPending(Display))
			X11.XNextEvent(Display, Event)
			print("Event", Event[0].type)
			if (Event[0].type == 22) then
				print"Game window resized"
				ShouldReobtainGameSurface = true
			elseif (Event[0].type == 17) then
				print"Game window lost"
				GameWindowMapped = false
				GameWindow = 0
				cqueues.sleep(1)
			elseif (Event[0].type == 19) then
				print"Game window mapped"
				GameWindowMapped = true
			end
		end
		
		if (not GameWindowMapped) or (GameWindow ~= Shared.FocusedWindow) then
			--print("Finding window", GameWindowName)
			GameWindow = Shared.FocusedWindow
			if GameWindow > 0 then
				print"Found game window"
				print"Redirecting game window to offscreen storage"
				--X11.XSetWMProtocols(Display, GameWindow, wm_delete_window, 1);
				Xcomposite.XCompositeRedirectWindow(Display, GameWindow, Xcomposite.CompositeRedirectAutomatic)
				X11.XSelectInput(Display, GameWindow, bit.lshift(1,17)) --TODO make constant in X11 library
				if GameSurface then
					print"Releasing previous surface"
					Capture.UnbindAndRelease(Display, GameSurface, Textures.Game)
				end
				GameSurface = Capture.ObtainAndBind(Display, FBConfig, GameWindow, GamePixmapAttributes, Textures.Game)
				GameWindowMapped = true
				ShouldReobtainGameSurface = true
			end
		elseif ShouldReobtainGameSurface then
			print"Reobtaining Game Surface"
			if GameSurface then
				print"Releasing previous surface"
				Capture.UnbindAndRelease(Display, GameSurface, Textures.Game)
			end
			GameSurface = Capture.ObtainAndBind(Display, FBConfig, GameWindow, GamePixmapAttributes, Textures.Game)
		end
		local X, Y = 0, 0
		if GameWindowMapped then
			local PtrX, PtrY = ffi.new"int[1]", ffi.new"int[1]"
			local Child = ffi.new"Window[1]"
			X11.XTranslateCoordinates(Display, GameWindow, Root, 0, 0, PtrX, PtrY, Child)
			X, Y = PtrX[0], PtrY[0]
		end
		local _, MouseX, MouseY = GetMousePosition(Display, Root)
		if (MouseX > 1920) and CursorHidden then
			CursorHidden = false
			Xfixes.XFixesShowCursor(Display, XWindow)
		elseif (MouseX <= 1920) and (not CursorHidden) then
			CursorHidden = true
			Xfixes.XFixesHideCursor(Display, XWindow)
		end
		RendererInstance:DrawOverlay(Shared, GameWindowMapped, X, Y, MouseX, 1080-MouseY, Textures, Synchronizer)
		GL.Lib.glXSwapBuffers(Display, GLWindow)
		cqueues.sleep(0)
	end
end
return Main
