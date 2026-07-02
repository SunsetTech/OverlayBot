local ffi = require"ffi"
local GL = require"OverlayBot.Rendering.GL"

local Utils; Utils = {
	ShowInfoLog = function(Object, glGet__iv, glGet__InfoLog)
		local LogLength = ffi.new"GLint[1]"
		glGet__iv(Object, GL.Lib.GL_INFO_LOG_LENGTH, LogLength)
		if LogLength[0] > 0 then
			local Log = ffi.new("char[?]", LogLength[0])
			glGet__InfoLog(Object, LogLength[0], nil, Log)
			local LogString = ffi.string(Log, LogLength[0])
			print(LogString)
			ffi.C.free(Log)
		end
	end;

	CompileShader = function(Type, Sources)
		local ShaderOK = ffi.new"GLint[1]"
		local ShaderHandle = GL.API.CreateShader(Type)
		local SourceCStrings = ffi.new("GLchar*[?]", #Sources)
		local SourceLengths = ffi.new("GLint[?]", #Sources)
		for Index, Source in pairs(Sources) do
			local CString = ffi.C.malloc(ffi.sizeof"GLchar" * (#Source+1))
			ffi.copy(CString, Source)
			SourceCStrings[Index-1] = CString
			SourceLengths[Index-1] = #Source
		end
		GL.API.ShaderSource(ShaderHandle, #Sources, ffi.cast("const char *const *", SourceCStrings), SourceLengths)
		GL.API.CompileShader(ShaderHandle)
		GL.API.GetShaderiv(ShaderHandle, GL.Lib.GL_COMPILE_STATUS, ShaderOK)
		if ShaderOK[0] == GL.Lib.GL_FALSE then
			Utils.ShowInfoLog(ShaderHandle, GL.API.GetShaderiv, GL.API.GetShaderInfoLog)
			error"Shader compilation failed"
		else
			return ShaderHandle
		end
	end;

	LinkProgram = function(ShaderHandles)
		local ProgramHandle = GL.API.CreateProgram()
		for _, ShaderHandle in pairs(ShaderHandles) do
			GL.API.AttachShader(ProgramHandle, ShaderHandle)
		end
		local ProgramOK = ffi.new"GLuint[1]"
		GL.API.LinkProgram(ProgramHandle)
		GL.API.GetProgramiv(ProgramHandle, GL.Lib.GL_LINK_STATUS,ProgramOK)
		if (ProgramOK[0] == GL.Lib.GL_FALSE) then
			Utils.ShowInfoLog(ProgramHandle, GL.API.GetProgramiv, GL.API.GetProgramInfoLog)
			error"Program linking failed"
		else
			return ProgramHandle
		end
	end;
	
	CreateVBO = function(Data, Type, Flags)
		local CArrayType = ffi.typeof("$[$]", ffi.typeof(Type), #Data)
		local CArray = CArrayType(Data)
		local Handle = ffi.new"GLuint[1]"
		GL.API.CreateBuffers(1, Handle)
		Handle = Handle[0]
		GL.API.NamedBufferStorage(Handle, #Data * ffi.sizeof(Type), CArray, Flags)
		return Handle
	end;

	CreateVAO = function(Bindings) 
		local Handle = ffi.new"GLuint[1]"
		GL.API.CreateVertexArrays(1, Handle)
		Handle = Handle[0]
		
		local UsedAttributeLocations = {}
		for Index, Binding in pairs(Bindings) do
			Index = Index - 1
			GL.API.VertexArrayVertexBuffer(Handle, Index, Binding.Handle, Binding.Offset, Binding.Stride)
			for _, Attribute in pairs(Binding.Attributes) do
				assert(not UsedAttributeLocations[Attribute.Location], "Attribute location collision")
				UsedAttributeLocations[Attribute.Location] = true
				GL.API.EnableVertexArrayAttrib(Handle, Attribute.Location)
				if Attribute.Mode == "I" then
					GL.API.VertexArrayAttribIFormat(Handle, Attribute.Location, Attribute.Size, Attribute.Type, Attribute.RelativeOffset)
				elseif Attribute.Mode == "L" then
					GL.API.VertexArrayAttribLFormat(Handle, Attribute.Location, Attribute.Size, Attribute.Type, Attribute.RelativeOffset)
				else
					GL.API.VertexArrayAttribFormat(Handle, Attribute.Location, Attribute.Size, Attribute.Type, Attribute.Normalized or false, Attribute.RelativeOffset)
				end
				GL.API.VertexArrayAttribBinding(Handle, Attribute.Location, Index)
			end
		end
		
		return Handle
	end;

	CreateTexture = function(Data, Width, Height, BitDepth)
		local Texture = ffi.new"GLuint[1]"
		GL.API.GenTextures(1, Texture)
		local Handle = Texture[0]
		GL.API.BindTexture(GL.Lib.GL_TEXTURE_2D, Handle)
		GL.API.TexImage2D(GL.Lib.GL_TEXTURE_2D, 0, GL.Lib.GL_RGBA, Width, Height, 0, GL.Lib.GL_RGBA, BitDepth == 16 and GL.Lib.GL_UNSIGNED_SHORT or GL.Lib.GL_UNSIGNED_BYTE, Data)
		GL.API.TexParameteri(GL.Lib.GL_TEXTURE_2D, GL.Lib.GL_TEXTURE_MIN_FILTER, GL.Lib.GL_LINEAR)
		GL.API.TexParameteri(GL.Lib.GL_TEXTURE_2D, GL.Lib.GL_TEXTURE_MAG_FILTER, GL.Lib.GL_LINEAR)
		GL.API.BindTexture(GL.Lib.GL_TEXTURE_2D, 0)
		return {
			Handle = Handle;
			Width = Width;
			Height = Height;
		}
	end;
}; return Utils;
