
local ffi = require "ffi"

local type = type

ffi.cdef[[
typedef struct tagRGBQUAD {
  uint8_t rgbBlue;
  uint8_t rgbGreen;
  uint8_t rgbRed;
  uint8_t rgbReserved;
} RGBQUAD;

__stdcall void*			FreeImage_OpenMemory(void* data, uint32_t size_in_bytes);
__stdcall void			FreeImage_CloseMemory(void* data);
__stdcall void*			FreeImage_LoadFromMemory(uint32_t format, void* stream, uint32_t flag);
__stdcall uint32_t		FreeImage_GetFileTypeFromMemory(void* stream, uint32_t flag);
__stdcall void*			FreeImage_ConvertTo32Bits(void* bitmap);
__stdcall uint32_t		FreeImage_GetWidth(void* bitmap);
__stdcall uint32_t		FreeImage_GetHeight(void* bitmap);
__stdcall uint8_t*		FreeImage_GetBits(void* bitmap);
__stdcall void			FreeImage_Unload(void* bitmap);
__stdcall void			FreeImage_Save(int format, void* bitmap, const char* path, int flags);
__stdcall const char*	FreeImage_GetFormatFromFIF(uint32_t fif);
__stdcall uint32_t		FreeImage_GetFIFFromFormat(const char* fmt);
__stdcall int			FreeImage_SaveToMemory(int format, void* bitmap, void* stream, int flags);
__stdcall int			FreeImage_AcquireMemory(void* stream, uint8_t** data, uint32_t* size);
__stdcall int			FreeImage_FlipVertical(void* bitmap);
__stdcall int			FreeImage_FlipHorizontal(void* bitmap);
__stdcall int			FreeImage_GetPixelColor(void* bitmap, unsigned int x, unsigned int y, RGBQUAD* color);
]]

local lib = ffi.load(ffi.os == "Windows" and "./dll/FreeImage" or "freeimage")

local FI = {}

function FI.open(data, len)
	local mem	= lib.FreeImage_OpenMemory(data, len)
	local fmt	= lib.FreeImage_GetFileTypeFromMemory(mem, 0)
	local base	= lib.FreeImage_LoadFromMemory(fmt, mem, 0)

	lib.FreeImage_CloseMemory(mem)
	if base == nil then return end

	local img 	= lib.FreeImage_ConvertTo32Bits(base)

	lib.FreeImage_Unload(base)
	if img == nil then return end

	return img, fmt, ffi.string(lib.FreeImage_GetFormatFromFIF(fmt))
end

local function getFmt(fmt)
	if type(fmt) == "string" then
		return lib.FreeImage_GetFIFFromFormat(fmt)
	end
	return fmt
end

function FI.saveToMemory(img, fmt)
	fmt = getFmt(fmt)
	local mem = lib.FreeImage_OpenMemory(nil, 0)
	lib.FreeImage_SaveToMemory(fmt, img, mem, 0)

	local ptr, size	= ffi.new("uint8_t*[1]"), ffi.new("unsigned long[1]")

	lib.FreeImage_AcquireMemory(mem, ptr, size)
	local copy = ffi.new("uint8_t[?]", size[0])
	ffi.copy(copy, ptr[0], size[0])
	lib.FreeImage_CloseMemory(mem)

	return copy, size[0]
end

function FI.saveToDisk(img, fmt, path)
	fmt = getFmt(fmt)
	lib.FreeImage_Save(fmt, img, path, 0)
end

function FI.close(img)
	lib.FreeImage_Unload(img)
end

function FI.getWidth(img)
	return lib.FreeImage_GetWidth(img)
end

function FI.getHeight(img)
	return lib.FreeImage_GetHeight(img)
end

function FI.getPixelBuffer(img)
	return lib.FreeImage_GetBits(img)
end

function FI.flipVertical(img)
	lib.FreeImage_FlipVertical(img)
end

function FI.flipHorizontal(img)
	lib.FreeImage_FlipHorizontal(img)
end

return FI
