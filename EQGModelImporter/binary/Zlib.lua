
local ffi		= require "ffi"
local BinUtil	= require "BinUtil"

local assert = assert

ffi.cdef[[
unsigned long compressBound(unsigned long sourceLen);
int compress2(uint8_t* dest, unsigned long* destLen, const uint8_t* source, unsigned long sourceLen, int level);
int uncompress(uint8_t* dest, unsigned long* destLen, const uint8_t* source, unsigned long sourceLen);
]]

local lib = ffi.load(ffi.os == "Windows" and "./dll/zlib1" or "z")

local zlib = {}

local buffer 	= BinUtil.ByteArray(16384)
local buflen 	= ffi.new("unsigned long[1]")

function zlib.Compress(data, len)
	assert(lib.compressBound(len) <= 16384)
	buflen[0] = 16384
	local res = lib.compress2(buffer, buflen, data, len, 9)
	assert(res == 0)
	return buffer, buflen[0]
end

function zlib.Decompress(data, len)
	buflen[0] = 16384
	local res = lib.uncompress(buffer, buflen, data, len)
	assert(res == 0)
	return buffer, buflen[0]
end

function zlib.compressWhole(data, len)
	data = ffi.cast(BinUtil.BytePtr, data)
	buflen[0] = lib.compressBound(len)
	local new = BinUtil.ByteArray(buflen[0])
	local res = lib.compress2(new, buflen, data, len, 9)
	assert(res == 0)
	return new, buflen[0]
end

function zlib.decompressWhole(data, orig_len)
	data = ffi.cast(BinUtil.BytePtr, data)
	buflen[0] = orig_len
	local new = BinUtil.ByteArray(orig_len)
	local res = lib.uncompress(new, buflen, data, orig_len)
	assert(res == 0)
	return new, buflen[0]
end

return zlib
