
local ffi		= require "ffi"
local EQGCommon	= require "EQGCommon"
local BinUtil	= require "BinUtil"
local Canvas	= require "model/Canvas"

ffi.cdef[[
typedef struct ModHeader {
	uint32_t	signature;		// "EQGM"
	uint32_t	version;
	uint32_t	stringBlockLen;
	uint32_t	materialCount;
	uint32_t	vertexCount;
	uint32_t	triangleCount;
	uint32_t	boneCount;
} ModHeader;
]]

local Header	= ffi.typeof("ModHeader")
local HeaderPtr	= ffi.typeof("ModHeader*")
local Signature	= BinUtil.toSignature("EQGM")

local Mod = {}

function Mod.open(data, len, name)
	local hlen = ffi.sizeof(Header)

	if hlen > len then
		error "file is too small to be a valid MOD"
	end

	local header = ffi.cast(HeaderPtr, data)

	if header.signature ~= Signature then
		error "file is not a valid MOD"
	end

	return EQGCommon.extractModel(header, data, len, hlen, name)
end

return Mod
