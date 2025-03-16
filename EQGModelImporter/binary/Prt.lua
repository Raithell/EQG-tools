
local ffi		= require "ffi"
local BinUtil	= require "BinUtil"

ffi.cdef[[
typedef struct PrtHeader {
	uint32_t	signature;	// "PTCL"
	uint32_t	count;
	uint32_t	version;
} PrtHeader;

typedef struct PrtData {
	uint32_t	particleID;			// particle id from ActorsEmittersNew.edd
	char		particleName[64];
	uint32_t	unknownA[5];
	uint32_t	duration;			// ? usually 5000
	uint32_t	unknownB;			// always seems to be 0
	uint32_t	unknownC;			// always seems to be 0xFFFFFFFF (color mask?)
	uint32_t	unknownD;			// 1 or 0, mostly 0
} PrtData;

typedef struct PrtEntry {
	PrtData		data;
} PrtEntry;

typedef struct PrtEntryV5 {
	PrtData		data;
	uint32_t	particleID2;	// seems to match particle id most of the time
} PrtEntryV5;
]]

local Header		= ffi.typeof("PrtHeader")
local HeaderPtr		= ffi.typeof("PrtHeader*")
local Entry			= ffi.typeof("PrtEntry")
local EntryPtr		= ffi.typeof("PrtEntry*")
local EntryV5		= ffi.typeof("PrtEntryV5")
local EntryV5Ptr	= ffi.typeof("PrtEntryV5*")
local Signature		= BinUtil.toSignature("PTCL")

local Prt = {}

function Prt.open(data, len)
	local p = ffi.sizeof(Header)

	if p > len then
		error "file is too small to be a valid PRT"
	end

	local header = ffi.cast(HeaderPtr, data)

	if header.signature ~= Signature then
		error "file is not a valid PRT"
	end

	local entries
	if header.version <= 4 then
		entries = ffi.cast(EntryPtr, data + p)
		p = p + ffi.sizeof(Entry) * header.count
	else
		entries = ffi.cast(EntryV5Ptr, data + p)
		p = p + ffi.sizeof(EntryV5) * header.count
	end

	if p > len then
		error "file is too short for the length of data indicated"
	end

	local info = {}

	for i = 0, header.count - 1 do
		local ent = entries[i].data

		local unkA = {}
		for i = 0, 4 do
			unkA[i + 1] = ent.unknownA[i]
		end

		info[i + 1] = {
			particleID		= ent.particleID,
			particleName	= ffi.string(ent.particleName),
			unknownA		= unkA,
			duration		= ent.duration,
			unknownB		= ent.unknownB,
			unknownC		= ent.unknownC,
			unknownD		= ent.unknownD,
		}
	end

	return info
end

return Prt
