local ffi = require"ffi"
local cglmPool = require"OverlayBot.Pool.cglm"
local GL = require"OverlayBot.Rendering.GL"
local Rendering = require"OverlayBot.Rendering"
local Assets = require"OverlayBot.Routines.Overlay.Assets"
local NDI = require"OverlayBot.Routines.Overlay.NDI"

local Utils = require"OverlayBot.Utils"

local OOP = require"Moonrise.OOP"

---@class OverlayBot.Routines.Overlay.Renderer
---@field StartTime number
---@field RenderTargets {Front: OverlayBot.Rendering.Utils.RenderTarget, Back: OverlayBot.Rendering.Utils.RenderTarget}
---@field Width integer
---@field Height integer
---@field BitDepth 16 | 8 | nil
---@field QuadVAO integer
---@field ProgramHandle integer
---@field WarpProgramHandle integer
---@field TransformationMatrixLocation integer
---@field TextureLocation integer
---@field PerspectiveMatrix OverlayBot.Math.cglm.Matrix4
---@field CameraPosition OverlayBot.Math.cglm.Vector3
---@field CameraTransform OverlayBot.Math.cglm.Matrix4
---@field InverseCameraTransform OverlayBot.Math.cglm.Matrix4
---@field cglm OverlayBot.Pool.cglm
---@overload fun(Width: integer, Height: integer): OverlayBot.Routines.Overlay.Renderer
---@diagnostic disable-next-line: assign-type-mismatch
local Renderer = OOP.Declarator.Shortcuts"OverlayBot.Routines.Overlay.Renderer"

---@param Instance OverlayBot.Routines.Overlay.Renderer
---@param Width integer
---@param Height integer
---@param BitDepth 16 | 8 | nil
function Renderer:Initialize(Instance, Width, Height, BitDepth)
	Instance.StartTime = Utils.GetTime()
	Instance.Width = Width
	Instance.Height = Height
	Instance.BitDepth = BitDepth
	
	Instance.RenderTargets = {
		Front = Rendering.Utils.CreateRenderTarget(Instance.Width, Instance.Height, Instance.BitDepth);
		Back = Rendering.Utils.CreateRenderTarget(Instance.Width, Instance.Height, Instance.BitDepth);
	}
	
	Instance.QuadVAO = Assets.CreateQuad()
	
	Instance.ProgramHandle = Assets.LoadDefaultShaderProgram()
	Instance.TransformationMatrixLocation = GL.API.GetUniformLocation(Instance.ProgramHandle, "TransformationMatrix")
	Instance.TextureLocation = GL.API.GetUniformLocation(Instance.ProgramHandle, "Texture")
	GL.API.BindFragDataLocation(Instance.ProgramHandle, 0, "FragmentColor")
	
	Instance.WarpProgramHandle = Assets.LoadWarpShaderProgram()
	
	Instance.cglm = cglmPool()
	local PerspectiveMatrix = Instance.cglm:Obtain"Matrix4"
	---@cast PerspectiveMatrix OverlayBot.Math.cglm.Matrix4
	Instance.PerspectiveMatrix = PerspectiveMatrix
	Instance.PerspectiveMatrix:MakePerspective(90*(math.pi/180),Instance.Width/Instance.Height,0,1000)
	
	Instance.CameraPosition = Instance.cglm:Obtain"Vector3"
	Instance.CameraPosition.Data[2] = 1
	
	local CameraTransform = Instance.cglm:Obtain"Matrix4"
	---@cast CameraTransform OverlayBot.Math.cglm.Matrix4
	
	Instance.CameraTransform = CameraTransform
	Instance.CameraTransform:MakeTranslation(Instance.CameraPosition)
	
	Instance.InverseCameraTransform = Instance.cglm:Obtain"Matrix4"
end

function Renderer:DrawImageToScreen(Texture, X, Y, ScaleX, ScaleY, Locations)
	Locations = Locations or {}
	ScaleX = ScaleX == nil and 1 or ScaleX
	ScaleY = ScaleY == nil and 1 or ScaleY
	
	local PositionMatrix = self.cglm:Obtain"Matrix4"
	---@cast PositionMatrix OverlayBot.Math.cglm.Matrix4
	X,Y = X or 0, Y or 0
	
	local PositionVector = self.cglm:Obtain"Vector3"
	PositionVector.Data[0] = (X*2-self.Width)/self.Height
	PositionVector.Data[1] = (Y*2-self.Height)/self.Height
	PositionVector.Data[2] = 0
	PositionMatrix:MakeTranslation(PositionVector)
	
	local ScaleVector = self.cglm:Obtain"Vector3"
	ScaleVector.Data[0] = Texture.Width/self.Height*ScaleX
	ScaleVector.Data[1] = Texture.Height/self.Height*ScaleY
	ScaleVector.Data[2] = 1
	
	local ScaleMatrix = self.cglm:Obtain"Matrix4"
	---@cast ScaleMatrix OverlayBot.Math.cglm.Matrix4
	ScaleMatrix:MakeScale(ScaleVector)
	
	local WorldMatrix = self.cglm:Multiply(PositionMatrix, ScaleMatrix)
	
	local TransformationMatrix = self.cglm:Multiply(self.cglm:Multiply(self.PerspectiveMatrix, self.InverseCameraTransform), WorldMatrix)
	
	GL.API.Uniform1i(Locations.Texture or self.TextureLocation, 0)
	GL.API.UniformMatrix4fv(Locations.TransformationMatrix or self.TransformationMatrixLocation, 1, GL.Lib.GL_FALSE, ffi.cast("const float*", TransformationMatrix.Data))
	GL.API.BindVertexArray(self.QuadVAO)
	GL.API.BindTextureUnit(0, Texture.Handle)
	GL.API.DrawArrays(GL.Lib.GL_TRIANGLES, 0, 6)
end

function Renderer:DrawOverlay(SharedData, GameWindowMapped, X, Y, Textures, Synchronizer)
	if SharedData.RenderOverlay then
		self.CameraTransform:InvertInto(self.InverseCameraTransform)
		GL.API.UseProgram(self.ProgramHandle)
		GL.API.BindFramebuffer(GL.Lib.GL_FRAMEBUFFER, self.RenderTargets.Front.Handle)
		GL.API.ClearColor(0.0, 0.0, 0.0, 0.0); 
		GL.API.Clear(GL.Lib.GL_COLOR_BUFFER_BIT)
		if GameWindowMapped then
			self:DrawImageToScreen(
				Textures.Game, 
				Textures.Game.Width/2 + X, 
				self.Height - Textures.Game.Height/2 - Y
			)
		end
		NDI.ReceiveFrameAndUpdateTexture(Synchronizer, Textures.NDISource)
		self:DrawImageToScreen(Textures.NDISource, self.Width/2, self.Height/2)
		if SharedData.FlashEnd >= Utils.GetTime() then
			GL.API.ClearColor(1,1,1,1)
			GL.API.Clear(GL.Lib.GL_COLOR_BUFFER_BIT)
			GL.API.Clear(GL.Lib.GL_DEPTH_BUFFER_BIT)
		end
		if SharedData.BSODEnd >= Utils.GetTime() then
			self:DrawImageToScreen(Textures.Overlays.BSOD, self.Width/2, self.Height/2)
		end
		if SharedData.PanicEnd >= Utils.GetTime() then
			self:DrawImageToScreen(Textures.Overlays.Panic, self.Width/2, self.Height/2)
		end
		for i = #SharedData.Buddies, 1, -1 do
			local BuddyInfo = SharedData.Buddies[i]
			if BuddyInfo.DieAt <= Utils.GetTime() then
				table.remove(SharedData.Buddies, i)
			else
				self:DrawImageToScreen(BuddyInfo.Texture, BuddyInfo.X, BuddyInfo.Y)
			end
		end
		if SharedData.WarpEnd >= Utils.GetTime() then
			self.RenderTargets.Front, self.RenderTargets.Back = self.RenderTargets.Back, self.RenderTargets.Front
			GL.API.UseProgram(self.WarpProgramHandle)
			GL.API.Uniform1f(GL.API.GetUniformLocation(self.WarpProgramHandle, "Time"), (Utils.GetTime() - self.StartTime) * SharedData.WarpSpeed)
			GL.API.Uniform1f(GL.API.GetUniformLocation(self.WarpProgramHandle, "Strength"), SharedData.WarpStrength / 100)
			GL.API.BindFramebuffer(GL.Lib.GL_FRAMEBUFFER, self.RenderTargets.Front.Handle)
			GL.API.ClearColor(0.0, 0.0, 0.0, 0.0); 
			GL.API.Clear(GL.Lib.GL_COLOR_BUFFER_BIT)
			GL.API.Clear(GL.Lib.GL_DEPTH_BUFFER_BIT)
			self:DrawImageToScreen(
				self.RenderTargets.Back.Texture, 
				self.Width/2, self.Height/2, 
				1, -1,
				{
					Texture = GL.API.GetUniformLocation(self.WarpProgramHandle, "Texture");
					TransformationMatrix = GL.API.GetUniformLocation(self.WarpProgramHandle, "TransformationMatrix");
				}
			)
		end
		GL.API.UseProgram(self.ProgramHandle)
		GL.API.BindFramebuffer(GL.Lib.GL_FRAMEBUFFER, 0)
		GL.API.ClearColor(0.0, 0.0, 0.0, 0.0); 
		GL.API.Clear(GL.Lib.GL_COLOR_BUFFER_BIT)
		GL.API.Clear(GL.Lib.GL_DEPTH_BUFFER_BIT)
		self:DrawImageToScreen(
			self.RenderTargets.Front.Texture, 
			self.Width/2, self.Height/2, 
			SharedData.XFlipEnd >= Utils.GetTime() and -1 or 1, 
			SharedData.YFlipEnd >= Utils.GetTime() and 1 or -1
		)
	end
end

return Renderer
