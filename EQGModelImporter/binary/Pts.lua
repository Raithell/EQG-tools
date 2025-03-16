
local ffi		= require "ffi"
local BinUtil	= require "BinUtil"

ffi.cdef[[
typedef struct PtsHeader {
	uint32_t	signature;	// "EQPT"
	uint32_t	count;
	uint32_t	version;
} PtsHeader;

typedef struct PtsEntry {
	char	particleName[64];
	char	attachName[64];
	float	x, y, z;
	float	rotX, rotY, rotZ;
	float	scaleX, scaleY, scaleZ;
} PtsEntry;
]]

local Header	= ffi.typeof("PtsHeader")
local HeaderPtr	= ffi.typeof("PtsHeader*")
local Entry		= ffi.typeof("PtsEntry")
local EntryPtr	= ffi.typeof("PtsEntry*")
local Signature	= BinUtil.toSignature("EQPT")

local Pts = {}

function Pts.open(data, len)
	local p = ffi.sizeof(Header)

	if p > len then
		error "file is too small to be a valid PTS"
	end

	local header = ffi.cast(HeaderPtr, data)

	if header.signature ~= Signature then
		error "file is not a valid PTS"
	end

	local entries = ffi.cast(EntryPtr, data + p)
	p = p + ffi.sizeof(Entry) * header.count

	if p > len then
		error "file is too short for the length of data indicated"
	end

	local info = {}

	for i = 0, header.count - 1 do
		local ent = entries + i

		info[i + 1] = {
			particleName	= ffi.string(ent.particleName),
			attachName		= ffi.string(ent.attachName),
			x				= BinUtil.fixFloat(ent.x),
			y				= BinUtil.fixFloat(ent.y),
			z				= BinUtil.fixFloat(ent.z),
			rotX			= BinUtil.fixFloat(ent.rotX),
			rotY			= BinUtil.fixFloat(ent.rotY),
			rotZ			= BinUtil.fixFloat(ent.rotZ),
			scaleX			= BinUtil.fixFloat(ent.scaleX),
			scaleY			= BinUtil.fixFloat(ent.scaleY),
			scaleZ			= BinUtil.fixFloat(ent.scaleZ),
		}
	end

	return info
end

return Pts
