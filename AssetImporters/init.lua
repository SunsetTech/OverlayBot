local Roses = require"Roses"
local Rendering = require"OverlayBot.Rendering"

local AssetImporters; AssetImporters = {
	PNG = require"OverlayBot.AssetImporters.PNG";
	WebP = require"OverlayBot.AssetImporters.WebP";
	
	---Loads a PNG into an OpenGL texture
	---@param Path string
	---@param Wrap {S: integer?, T: integer?}?
	---@param Filter {Min: integer?, Mag: integer?}?
	LoadPNG = function(Path, Wrap, Filter)
		Path = Roses.Directory.System.Data"OverlayBot" .."/".. Path
		print("Reading", Path)
		local Image, Error = AssetImporters.PNG(Path)
		print("LoadPNG", Image, Error)
		if not Image then return nil, Error end
		return Rendering.Utils.CreateTexture(Image.Data, Image.Width, Image.Height, Image.BitDepth, Wrap, Filter)
	end;
	CreateTextureFromWebP = function(Path)
	end;
}; return AssetImporters
