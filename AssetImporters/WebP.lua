local ffi = require"ffi"
local libwebp = require"libwebp.FFI"
local bit = require"bit"
local Image = require"OverlayBot.Image"
local Roses = require"Roses"
require"JiFFI.Helpers.CSTD"

local function ImgIoUtilReadFile(Path)
	local Input = ffi.C.fopen(Path, "rb")
	if (Input == ffi.NULL) then return nil, "Couldn't open file" end
	ffi.C.fseek(Input, 0, ffi.C.SEEK_END)
	local FileSize = ffi.C.ftell(Input)
	ffi.C.fseek(Input, 0, ffi.C.SEEK_SET)
	local FileData = ffi.cast("uint8_t*", ffi.C.malloc(FileSize + 1))
	if (FileData == ffi.NULL) then return nil, "Memory allocation failed" end
	local OK = ffi.C.fread(FileData, FileSize, 1, Input) == 1
	if not OK then 
		libwebp.WebPFree(FileData)
		return nil, "Failed to read file" 
	end
	FileData[FileSize] = 0
	return {
		Data = FileData;
		Size = FileSize;
	}
end

local function EXUtilReadFileToWebPData(Path) -- NOTE: If I remember correctly, this function and the one above are taken from the libwebp headers
	local FileData, Error = ImgIoUtilReadFile(Path)
	if not FileData then return nil, Error end
	local Bitstream = ffi.new"WebPData[1]"
	Bitstream[0].bytes = FileData.Data
	Bitstream[0].size = FileData.Size
	return Bitstream
end

local function WebPMuxCreate(Bitstream, CopyData)
	return libwebp.mux.WebPMuxCreateInternal(Bitstream, CopyData, 0x0109) -- TODO: the last parameter needs to be programatically obtained from somewhere
end

local function CreateMux(Bitstream)
	local Mux = WebPMuxCreate(Bitstream, true)
	if (Mux ~= ffi.NULL) then return Mux end
	return nil, "Failed to create mux object from file"
end

local function TestFlag(Flags, Flag)
	return bit.band(Flags, Flag) ~= 0
end

local function WebPAnimDecoderNew(Data, Options)
	return libwebp.demux.WebPAnimDecoderNewInternal(Data, Options, libwebp.demux.WEBP_DEMUX_ABI_VERSION)
end

return function(Path) -- TODO: cleanup memory before exit
	Path = Roses.Directory.System.Data"OverlayBot" .."/".. Path
	local Bitstream, Error = EXUtilReadFileToWebPData(Path)
	if not Bitstream then return nil, Error end
	local Mux; Mux, Error = CreateMux(Bitstream)
	if not Mux then return nil, Error end

	local Width = ffi.new"int[1]"
	local Height = ffi.new"int[1]"
	local BytesPerFrame = Width[0]*Height[0]*4
	Error = libwebp.mux.WebPMuxGetCanvasSize(Mux, Width, Height)
	if Error ~= libwebp.webp.WEBP_MUX_OK then return nil, Error end -- TODO: return something better
	
	local Flags = ffi.new"uint32_t[1]"
	Error = libwebp.mux.WebPMuxGetFeatures(Mux, Flags)
	Flags = Flags[0]
	if Error ~= libwebp.webp.WEBP_MUX_OK then return nil, Error end
	if TestFlag(Flags, libwebp.mux.ANIMATION_FLAG) then
		local AnimatedImage = Image.Animated(Width[0], Height[0])
		local AnimInfo = ffi.new"WebPAnimInfo[1]"
		local Decoder = WebPAnimDecoderNew(Bitstream, ffi.NULL)
		local Success = libwebp.demux.WebPAnimDecoderGetInfo(Decoder, AnimInfo)
		if not Success then return false, "Couldn't get animation info" end
		local FrameIndex = 1
		while libwebp.demux.WebPAnimDecoderHasMoreFrames(Decoder) == 1 do
			local FrameRGBA = ffi.new"uint8_t*[1]"
			local Timestamp = ffi.new"int[1]"
			Success = libwebp.demux.WebPAnimDecoderGetNext(Decoder, FrameRGBA, Timestamp)
			if Success == 0 then return nil, "Couldn't decode a frame" end
			local FrameCopy = ffi.new("uint8_t[?]",BytesPerFrame)
			ffi.copy(FrameCopy,FrameRGBA[0],BytesPerFrame)
			AnimatedImage:AddFrame(FrameCopy, Timestamp[0])
			FrameIndex = FrameIndex+1
		end
		
		return AnimatedImage
	else
		local FileData = Bitstream[0].bytes
		local FileSize = Bitstream[0].size
		local ImageData = libwebp.decoder.WebPDecodeRGBA(FileData, FileSize, ffi.NULL, ffi.NULL)
		return Image.Static(ImageData, Width[0], Height[0])
	end
end
