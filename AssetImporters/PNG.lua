local ffi = require"ffi"
require"JiFFI.Helpers.CSTD"

local libpng = require"libpng.FFI"

return function(Path) -- TODO: Ensure memory is cleaned up
	local FilePointer = ffi.C.fopen(Path, "rb")
	if FilePointer == nil then
		return nil, "Failed to open file"
	end
	
	local PNG = libpng.png_create_read_struct("1.6.43\0", ffi.NULL, ffi.NULL, ffi.NULL)
	if PNG == nil then
		ffi.C.fclose(FilePointer)
		return nil, "Failed to create read struct"
	end

	local Info = libpng.png_create_info_struct(PNG)
	if Info == nil then
		ffi.C.fclose(FilePointer)
		libpng.png_destroy_read_struct(ffi.new("png_structp[1]", PNG), ffi.NULL, ffi.NULL)
		return nil, "Failed to create Info struct"
	end
	libpng.png_init_io(PNG, FilePointer)
	libpng.png_read_info(PNG, Info)

	local Width = libpng.png_get_image_width(PNG, Info)
	local Height = libpng.png_get_image_height(PNG, Info)
	local BitDepth = libpng.png_get_bit_depth(PNG, Info)
	local ColorType = libpng.png_get_color_type(PNG, Info)
	if (BitDepth ~= 8 and BitDepth ~= 16) then
		return nil, "unsupported bit depth ".. BitDepth
	end
	if (ColorType ~= 6) then
		return nil, "unsupported color type ".. ColorType
	end

	libpng.png_read_update_info(PNG, Info)

	local RowBytes = libpng.png_get_rowbytes(PNG, Info)
	local ImageDataSize = Height * RowBytes
	local ImageData = ffi.new("unsigned char[?]", ImageDataSize)

	local Rows = ffi.new("png_bytep[?]", Height)
	for Y = 0, Height - 1 do
		Rows[Y] = ImageData + Y * RowBytes
	end

	libpng.png_read_image(PNG, Rows)
	ffi.C.fclose(FilePointer)
	libpng.png_destroy_read_struct(ffi.new("png_structp[1]", PNG), ffi.new("png_infop[1]", Info), ffi.NULL)
	
	local DataSize = BitDepth / 2
	local PixelData = ffi.new("png_byte[?]", Width * Height * DataSize)
	
	local PixelIndex = 0
	for Y = 0, Height-1 do
		local Row = Rows[Y]
		for X = 0, Width-1 do
			for Index = 0, DataSize-1 do
				PixelData[PixelIndex*DataSize+Index] = Row[X*DataSize+Index]
			end
			PixelIndex = PixelIndex+1
		end
	end
	
	return {
		Width = Width;
		Height = Height;
		Data = PixelData;
		BitDepth = BitDepth;
		ColorType = ColorType;
	}
end
