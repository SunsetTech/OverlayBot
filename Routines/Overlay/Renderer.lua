local ffi = require"ffi"
local cglmPool = require"OverlayBot.Pool.cglm"
local GL = require"OverlayBot.Rendering.GL"
local Assets = require"OverlayBot.Routines.Overlay.Assets"
local NDI = require"OverlayBot.Routines.Overlay.NDI"

local Utils = require"OverlayBot.Utils"

local OOP = require"Moonrise.OOP"

---@class OverlayBot.Routines.Overlay.Renderer
---@overload fun(): OverlayBot.Routines.Overlay.Renderer
---@field QuadVAO integer
---@field ProgramHandle integer
---@field TransformationMatrixLocation integer
---@field TextureLocation integer
---@field PerspectiveMatrix OverlayBot.Math.cglm.Matrix4
---@field CameraPosition OverlayBot.Math.cglm.Vector3
---@field CameraTransform OverlayBot.Math.cglm.Matrix4
---@field InverseCameraTransform OverlayBot.Math.cglm.Matrix4
---@field cglm OverlayBot.Pool.cglm
---@diagnostic disable-next-line: assign-type-mismatch
local Renderer = OOP.Declarator.Shortcuts"OverlayBot.Routines.Overlay.Renderer"

function Renderer:Initialize(Instance)
	Instance.QuadVAO = Assets.CreateQuad()
	
	Instance.ProgramHandle = Assets.LoadDefaultShaderProgram()
	Instance.TransformationMatrixLocation = GL.API.GetUniformLocation(Instance.ProgramHandle, "TransformationMatrix")
	Instance.TextureLocation = GL.API.GetUniformLocation(Instance.ProgramHandle, "Texture")
	GL.API.BindFragDataLocation(Instance.ProgramHandle, 0, "FragmentColor")
	GL.API.UseProgram(Instance.ProgramHandle)
	
	Instance.cglm = cglmPool()
	local PerspectiveMatrix = Instance.cglm:Obtain"Matrix4"
	---@cast PerspectiveMatrix OverlayBot.Math.cglm.Matrix4
	Instance.PerspectiveMatrix = PerspectiveMatrix
	Instance.PerspectiveMatrix:MakePerspective(90*(math.pi/180),1920/1080,0,1000)
	
	Instance.CameraPosition = Instance.cglm:Obtain"Vector3"
	Instance.CameraPosition.Data[2] = 1
	
	local CameraTransform = Instance.cglm:Obtain"Matrix4"
	---@cast CameraTransform OverlayBot.Math.cglm.Matrix4
	
	Instance.CameraTransform = CameraTransform
	Instance.CameraTransform:MakeTranslation(Instance.CameraPosition)
	
	Instance.InverseCameraTransform = Instance.cglm:Obtain"Matrix4"
end

function Renderer:DrawImageToScreen(Texture, X, Y, ScaleX, ScaleY)
	ScaleX = ScaleX == nil and 1 or ScaleX
	ScaleY = ScaleY == nil and 1 or ScaleY
	
	local PositionMatrix = self.cglm:Obtain"Matrix4"
	---@cast PositionMatrix OverlayBot.Math.cglm.Matrix4
	X,Y = X or 0, Y or 0
	
	local PositionVector = self.cglm:Obtain"Vector3"
	PositionVector.Data[0] = (X*2-1920)/1080
	PositionVector.Data[1] = (Y*2-1080)/1080
	PositionVector.Data[2] = 0
	PositionMatrix:MakeTranslation(PositionVector)
	
	local ScaleVector = self.cglm:Obtain"Vector3"
	ScaleVector.Data[0] = Texture.Width/1080*ScaleX
	ScaleVector.Data[1] = Texture.Height/1080*ScaleY
	ScaleVector.Data[2] = 1
	
	local ScaleMatrix = self.cglm:Obtain"Matrix4"
	---@cast ScaleMatrix OverlayBot.Math.cglm.Matrix4
	ScaleMatrix:MakeScale(ScaleVector)
	
	local WorldMatrix = self.cglm:Multiply(PositionMatrix, ScaleMatrix)
	
	local TransformationMatrix = self.cglm:Multiply(self.cglm:Multiply(self.PerspectiveMatrix, self.InverseCameraTransform), WorldMatrix)
	
	GL.API.Uniform1i(self.TextureLocation, 0)
	GL.API.UniformMatrix4fv(self.TransformationMatrixLocation, 1, GL.Lib.GL_FALSE, ffi.cast("const float*", TransformationMatrix.Data))
	GL.API.BindVertexArray(self.QuadVAO)
	GL.API.BindTextureUnit(0, Texture.Handle)
	GL.API.DrawArrays(GL.Lib.GL_TRIANGLES, 0, 6)
end

function Renderer:DrawOverlay(SharedData, GameWindowMapped, X, Y, Textures, Synchronizer)
	GL.API.ClearColor(0.0, 0.0, 0.0, 0.0); 
	GL.API.Clear(GL.Lib.GL_COLOR_BUFFER_BIT)
	GL.API.Clear(GL.Lib.GL_DEPTH_BUFFER_BIT)

	self.CameraTransform:InvertInto(self.InverseCameraTransform)
	if SharedData.RenderOverlay then
		if GameWindowMapped then
			self:DrawImageToScreen(
				Textures.Game, 
				Textures.Game.Width/2 + X, 
				1080 - Textures.Game.Height/2 - Y, 
				SharedData.XFlipEnd >= Utils.GetTime() and -1 or 1, 
				SharedData.YFlipEnd >= Utils.GetTime() and -1 or 1
			)
		end
		NDI.ReceiveFrameAndUpdateTexture(Synchronizer, Textures.NDISource)
		self:DrawImageToScreen(Textures.NDISource, 1920/2, 1080/2)
		if SharedData.FlashEnd >= Utils.GetTime() then
			GL.API.ClearColor(1,1,1,1)
			GL.API.Clear(GL.Lib.GL_COLOR_BUFFER_BIT)
			GL.API.Clear(GL.Lib.GL_DEPTH_BUFFER_BIT)
		end
		if SharedData.BSODEnd >= Utils.GetTime() then
			self:DrawImageToScreen(Textures.Overlays.BSOD, 1920/2, 1080/2)
		end
		if SharedData.PanicEnd >= Utils.GetTime() then
			self:DrawImageToScreen(Textures.Overlays.Panic, 1920/2, 1080/2)
		end
		for i = #SharedData.Buddies, 1, -1 do
			local BuddyInfo = SharedData.Buddies[i]
			if BuddyInfo.DieAt <= Utils.GetTime() then
				table.remove(SharedData.Buddies, i)
			else
				self:DrawImageToScreen(BuddyInfo.Texture, BuddyInfo.X, BuddyInfo.Y)
			end
		end
	end
end

return Renderer
