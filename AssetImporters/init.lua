local Roses = require"Roses"
local Rendering = require"OverlayBot.Rendering"

local AssetImporters; AssetImporters = {
	PNG = require"OverlayBot.AssetImporters.PNG";
	WebP = require"OverlayBot.AssetImporters.WebP";
	LoadPNG = function(Path)
		Path = Roses.Directory.System.Data"OverlayBot" .."/".. Path
		print("Reading", Path)
		local Image, Error = AssetImporters.PNG(Path)
		if not Image then return nil, Error end
		return Rendering.Utils.CreateTexture(Image.Data, Image.Width, Image.Height, Image.BitDepth)
	end;
	CreateTextureFromWebP = function(Path)
	end;
}; return AssetImporters
