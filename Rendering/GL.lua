local GL = {
	API = require"ffibuild.opengl.opengl";
	Lib = require"OpenGL";
}
GL.API.Initialize(GL.Lib.glXGetProcAddress)

return GL
