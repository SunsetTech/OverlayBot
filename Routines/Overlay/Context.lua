local ffi = require"ffi"
local GL = require"OverlayBot.Rendering.GL"

local Context; Context = {
	Setup = function()
		GL.API.Enable(GL.Lib.GL_TEXTURE_2D)
		GL.API.Enable(GL.Lib.GL_BLEND);
		GL.API.Enable(GL.Lib.GL_DEPTH_TEST); 
		GL.API.Enable(GL.Lib.GL_DEPTH_CLAMP);
		GL.API.Enable(GL.Lib.GL_DEBUG_OUTPUT);
		
		GL.API.BlendFunc(GL.Lib.GL_SRC_ALPHA, GL.Lib.GL_ONE_MINUS_SRC_ALPHA);
		GL.API.DepthFunc(GL.Lib.GL_LEQUAL); 
		GL.API.DepthRange(0.0, 1.0); 
		GL.API.ClearDepth(1.0); 
		GL.API.Viewport(0,0,1920,1080)
		
		GL.API.DebugMessageCallback(
			function(Source, Type, ID, Severity, Length, Message)
				print(Source, Type, ID, Severity, Length, ffi.string(Message))
			end, nil
		)
	end;
}; return Context;
