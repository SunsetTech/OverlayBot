local ffi = require"ffi"
local libndi = require"libndi"
local GL = require"OverlayBot.Rendering.GL"
local cqueues = require"cqueues"

local NDI; NDI = {
	Initialize = function()
		assert(libndi.Library.NDIlib_is_supported_CPU())
		assert(libndi.Library.NDIlib_initialize())
	end;
	
	CreateFinder = function(Settings)
		local FinderSettings = ffi.new( "const NDIlib_find_create_t[1]", {Settings})
		local NDIFinder = libndi.Library.NDIlib_find_create_v2(FinderSettings)
		return NDIFinder
	end;
	
	WaitForSources = function(Finder)
		repeat 
			print"Waiting for NDI sources" 
		until (libndi.Library.NDIlib_find_wait_for_sources(Finder, 1000))
	end;
	
	FindSource = function(Finder, Name)
		local SourceCount = ffi.new"uint32_t[1]"
		local Sources = libndi.Library.NDIlib_find_get_current_sources(Finder, SourceCount)
		for Index = 1, SourceCount[0] do
			Index = Index - 1
			local CandidateSource = Sources[Index]
			local CandidateName = ffi.string(CandidateSource.p_ndi_name)
			if CandidateName == Name then
				print"Found target source"
				print(ffi.string(CandidateSource.p_ip_address))
				return CandidateSource
			end
		end
	end;
	
	WaitForSource = function(Finder, Name)
		local CandidateSource
		repeat
			repeat
				cqueues.sleep(0)
			until (libndi.Library.NDIlib_find_wait_for_sources(Finder, 0))
			CandidateSource = NDI.FindSource(Finder, Name)
			print(CandidateSource)
			cqueues.sleep(0)
		until CandidateSource ~= nil
		return CandidateSource
	end;
	
	CreateReceiver = function(Settings)
		local ReceiveSettings = ffi.new( "const NDIlib_recv_create_v3_t[1]", {Settings})
		return libndi.Library.NDIlib_recv_create_v3(ReceiveSettings)
	end;
	
	CreateSynchronizer = function(Receiver)
		return libndi.Library.NDIlib_framesync_create(Receiver)
	end;
	
	CreateTexture = function()
		local NDITextureHandle = ffi.new"GLuint[1]"
		GL.API.GenTextures(1, NDITextureHandle)
		NDITextureHandle = NDITextureHandle[0]
		GL.API.BindTexture(GL.Lib.GL_TEXTURE_2D, NDITextureHandle)
		GL.API.TexParameteri(GL.Lib.GL_TEXTURE_2D, GL.Lib.GL_TEXTURE_MIN_FILTER, GL.Lib.GL_LINEAR)
		GL.API.TexParameteri(GL.Lib.GL_TEXTURE_2D, GL.Lib.GL_TEXTURE_MAG_FILTER, GL.Lib.GL_LINEAR)
		GL.API.TexImage2D(GL.Lib.GL_TEXTURE_2D, 0, GL.Lib.GL_RGBA, 1920, 1080, 0, GL.Lib.GL_RGBA, GL.Lib.GL_UNSIGNED_BYTE, nil)

		return {
			Handle = NDITextureHandle;
			Width = 1920;
			Height = 1080;
		}
	end;
	
	ReceiveFrameAndUpdateTexture = function(Synchronizer, Texture)
		local Frame = ffi.new"NDIlib_video_frame_v2_t[1]"
		libndi.Library.NDIlib_framesync_capture_video(Synchronizer, Frame, libndi.Library.NDIlib_frame_format_type_progressive)
		local FrameData = Frame[0].p_data
		if FrameData ~= nil then
			GL.API.TextureSubImage2D(Texture.Handle, 0, 0, 0, 1920, 1080, GL.Lib.GL_RGBA, GL.Lib.GL_UNSIGNED_BYTE, FrameData)
		end
		libndi.Library.NDIlib_framesync_free_video(Synchronizer, Frame)
	end
}; return NDI;
