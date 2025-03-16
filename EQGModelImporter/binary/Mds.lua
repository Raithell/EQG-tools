
local ffi		= require "ffi"
local EQGCommon	= require "EQGCommon"
local BinUtil	= require "BinUtil"
local Model		= require "Model"
local SubModel	= require "SubModel"
local Skeleton	= require "Skeleton"

ffi.cdef[[
typedef struct MdsHeader {
	uint32_t	signature;		// "EQGS"
	uint32_t	version;
	uint32_t	stringBlockLen;
	uint32_t	materialCount;
	uint32_t	boneCount;
	uint32_t	modelCount;
} MdsHeader;

typedef struct MdsSubHeader {
	uint32_t	mainPiece;			// 1 = yes, 0 = no; yes applies to both the main body and default "head"
	uint32_t	nameIndex;
	uint32_t	vertexCount;
	uint32_t	triangleCount;
	uint32_t	boneAssignCount;
} MdsSubHeader;
]]

local Header		= ffi.typeof("MdsHeader")
local HeaderPtr		= ffi.typeof("MdsHeader*")
local SubHeader		= ffi.typeof("MdsSubHeader")
local SubHeaderPtr	= ffi.typeof("MdsSubHeader*")
local Signature		= BinUtil.toSignature("EQGS")

local Mds = {}

function Mds.open(data, len, name)
	local p = ffi.sizeof(Header)

	if p > len then
		error "file is too small to be a valid MDS"
	end

	local header = ffi.cast(HeaderPtr, data)

	if header.signature ~= Signature then
		error "file is not a valid MDS"
	end

	local strings, materials, skeleton

	strings, p		= EQGCommon.extractStrings(header, data, len, p)
	materials, p	= EQGCommon.extractMaterials(header, strings, data, len, p)

	-- skip over skeleton for now, we'll have to do it multiple times, once for each sub model
	local pSkele = p
	p = p + ffi.sizeof(EQGCommon.Bone) * header.boneCount

	local model = Model.new(name, materials)

	for i = 1, header.modelCount do
		local subHeader = ffi.cast(SubHeaderPtr, data + p)
		p = p + ffi.sizeof(SubHeader)

		local name = strings[subHeader.nameIndex]

		local sections, tris, skeleton, bonesLO, bonesRO
		sections, p, tris	= EQGCommon.extractModelSections(subHeader, header.version, materials, data, len, p)
		bonesLO, bonesRO	= EQGCommon.extractBones(header, strings, data, len, pSkele)
		skeleton, p			= EQGCommon.extractSkeleton(bonesLO, bonesRO, subHeader.boneAssignCount, tris, subHeader.triangleCount, data, len, p)

		local sub = SubModel.new(sections, skeleton, name)

		if name:find("^...HE") then
			model:addAlternateSubModel(sub)
		else
			model:setMainSubModel(sub)
		end
	end

	return model
end

return Mds
