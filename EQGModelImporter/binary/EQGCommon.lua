
--------------------------------------------------------------------------------
-- EQGCommon.lua
--
-- Provides generic routines to extract binary model data from any EQG model
-- file type, including Mod, Mds and Ter.
-- Also handles the conversion of such data to the common, high-level
-- representations used by this tool.
--------------------------------------------------------------------------------

local ffi			= require "ffi"
local BinUtil		= require "BinUtil"
local Property		= require "Property"
local Material		= require "Material"
local VertexBuffer	= require "VertexBuffer"
local ModelSection	= require "ModelSection"
local Matrix		= require "Matrix"
local Skeleton		= require "Skeleton"
local Bone			= require "Bone"
local WeightBuffer	= require "WeightBuffer"
local SubModel		= require "SubModel"
local Model			= require "Model"
local S3D			= require "S3D"

local table	= table
local pairs = pairs

ffi.cdef[[
#pragma pack(1)

typedef struct EQG_Color {
	uint8_t a;
	uint8_t r;
	uint8_t g;
	uint8_t b;
} EQG_Color;

typedef struct EQG_Property {
	uint32_t typeNameIndex;	// index of the property's type name in the file's string block
	uint32_t valueType;		// type of the property's value: 0 = float, 2 = string index int, 3 = ARGB color value int
	union {
		uint32_t	asIndex;
		float		asFloat;
		EQG_Color	asColor;
	} value;
} EQG_Property;

typedef struct EQG_Material {
	uint32_t 		index;			// essentially meaningless
	uint32_t 		nameIndex;		// index of the material's name in the file's string block
	uint32_t 		shaderIndex;	// index of the name of the shader to use for this material in the file's string block
	uint32_t 		propertyCount;	// number of EQG_Property elements following this material
	EQG_Property	properties[0];	// properties array accessor
} EQG_Material;

typedef Vertex EQG_Vertex;	// from VertexBuffer.lua

typedef struct EQG_VertexV3 {
	float		x, y, z;	// position
	float		i, j, k;	// normal
	uint32_t	unk_i;
	float		u, v;		// texture coordinates
	float		unk_f[2];
} EQG_VertexV3;

typedef struct EQG_Triangle {
	uint32_t	index[3];
	int			materialIndex;	// index of the material used by this triangle
	uint32_t	flag;
} EQG_Triangle;

typedef struct EQG_Pos {
	float x, y, z;
} EQG_Pos;

typedef struct EQG_Quat {
	float x, y, z, w;
} EQG_Quat;

typedef struct EQG_Bone {
	uint32_t	nameIndex;
	uint32_t	linkBoneIndex;
	uint32_t	flag;
	uint32_t	childBoneIndex;
	EQG_Pos		pos;
	EQG_Quat	rot;
	EQG_Pos		scale;
} EQG_Bone;

typedef struct EQG_BoneWeight {
	int		boneIndex;
	float	value;
} EQG_BoneWeight;

typedef struct EQG_BoneAssignment {
	uint32_t		count;		// number of weights actually used; there's always space for 4
	EQG_BoneWeight	weights[4];
} EQG_BoneAssignment;

#pragma pack()
]]

local EQGCommon = {
	Property			= ffi.typeof("EQG_Property"),
	PropertyPtr			= ffi.typeof("EQG_Property*"),
	Material			= ffi.typeof("EQG_Material"),
	MaterialPtr			= ffi.typeof("EQG_Material*"),
	Vertex				= ffi.typeof("EQG_Vertex"),
	VertexPtr			= ffi.typeof("EQG_Vertex*"),
	VertexV3			= ffi.typeof("EQG_VertexV3"),
	VertexV3Ptr			= ffi.typeof("EQG_VertexV3*"),
	Triangle			= ffi.typeof("EQG_Triangle"),
	TrianglePtr			= ffi.typeof("EQG_Triangle*"),
	Bone				= ffi.typeof("EQG_Bone"),
	BonePtr				= ffi.typeof("EQG_Bone*"),
	BoneAssignment		= ffi.typeof("EQG_BoneAssignment"),
	BoneAssignmentPtr	= ffi.typeof("EQG_BoneAssignment*"),
}

local function tooShort()
	error "file is too short for the length of data indicated"
end

function EQGCommon.extractStrings(header, data, len, p)
	local stringBlock = ffi.cast(BinUtil.CharPtr, data + p)
	p = p + header.stringBlockLen

	if p > len then tooShort() end

	-- create a table mapping string indices to lua strings
	local strings = {}
	local i	= 0

	while i < header.stringBlockLen do
		local str = ffi.string(stringBlock + i)
		strings[i] = str
		i = i + #str + 1 -- need to skip null terminator
	end

	return strings, p
end

local propertyHandler = {
	-- float
	[0] = function(binProp, prop)
		prop:setValueFloat(BinUtil.fixFloat(binProp.value.asFloat))
	end,

	-- unused?
	[1] = function()

	end,

	-- string index
	[2] = function(binProp, prop, strings)
		prop:setValueString(strings[binProp.value.asIndex])
	end,

	-- RGBA color
	[3] = function(binProp, prop)
		local color = binProp.value.asColor
		prop:setValueColor(binProp.value.asIndex, color)
	end,
}

function EQGCommon.extractMaterials(header, strings, data, len, p)
	local s3d = S3D.getCurrent()
	local materials = {}

	for i = 1, header.materialCount do
		local binMat = ffi.cast(EQGCommon.MaterialPtr, data + p)
		p = p + ffi.sizeof(EQGCommon.Material)

		if p > len then tooShort() end

		p = p + ffi.sizeof(EQGCommon.Property) * binMat.propertyCount

		if p > len then tooShort() end

		local mat = Material.new(strings[binMat.nameIndex], strings[binMat.shaderIndex], s3d)

		table.insert(materials, mat)

		for j = 0, binMat.propertyCount - 1 do
			local binProp	= binMat.properties[j]
			local prop		= Property.new(strings[binProp.typeNameIndex])

			propertyHandler[binProp.valueType](binProp, prop, strings)

			mat:addProperty(prop)
		end
	end

	return materials, p
end

function EQGCommon.extractModelSections(header, version, materials, data, len, p)
	local vertexBuffers = {}
	local sections = {}
	local vertices, addVertex

	if version < 3 then
		vertices = ffi.cast(EQGCommon.VertexPtr, data + p)
		p = p + ffi.sizeof(EQGCommon.Vertex) * header.vertexCount
	else
		vertices = ffi.cast(EQGCommon.VertexV3Ptr, data + p)
		p = p + ffi.sizeof(EQGCommon.VertexV3) * header.vertexCount
	end

	local tris = ffi.cast(EQGCommon.TrianglePtr, data + p)
	p = p + ffi.sizeof(EQGCommon.Triangle) * header.triangleCount

	if p > len then tooShort() end

	local function getVertBuffer(index)
		local buf = vertexBuffers[index]
		if buf then return buf end
		buf = VertexBuffer.new()
		vertexBuffers[index] = buf
		sections[index + 1] = ModelSection.new(buf, materials[index + 1])
		return buf
	end

	for i = 0, header.triangleCount - 1 do
		local tri = tris[i]
		local buf = getVertBuffer(tri.materialIndex)
		for j = 0, 2 do
			buf:addVertex(vertices + tri.index[j])
		end
	end

	return sections, p, tris
end

function EQGCommon.extractBones(header, strings, data, len, p)
	local binBones = ffi.cast(EQGCommon.BonePtr, data + p)
	p = p + ffi.sizeof(EQGCommon.Bone) * header.boneCount

	if p > len then tooShort() end

	local bonesRecurseOrder = {}
	local bonesListOrder = {}

	for i = 0, header.boneCount - 1 do
		local bone = binBones + i
		local name = strings[bone.nameIndex]:upper()

		local bPos = bone.pos
		local bRot = bone.rot
		local bScl = bone.scale

		local pos	= Matrix.translation(bPos.x, bPos.y, bPos.z)
		local rot	= Matrix.fromQuaternion(bRot)
		local scale = Matrix.scale(bScl.x, bScl.y, bScl.z)

		table.insert(bonesListOrder, Bone.new(name, pos * rot * scale))
	end

	local function recurse(i, parent)
		local binBone = binBones + i
		local bone = bonesListOrder[i + 1]

		if binBone.linkBoneIndex ~= 0xFFFFFFFF then
			recurse(binBone.linkBoneIndex, parent)
		end

		table.insert(bonesRecurseOrder, bone)

		if parent then
			bone:setParent(parent)
			bone:setGlobalMatrix(parent:getGlobalMatrix() * bone:getLocalMatrix())
		else
			bone:setGlobalMatrix(bone:getLocalMatrix():copy())
		end

		if binBone.childBoneIndex ~= 0xFFFFFFFF then
			recurse(binBone.childBoneIndex, bone)
		end
	end

	recurse(0)

	return bonesListOrder, bonesRecurseOrder, p
end

function EQGCommon.extractSkeleton(bonesListOrder, bonesRecurseOrder, baCount, tris, triCount, data, len, p)
	local skele = Skeleton.new()

	-- bone assignments come in two indexing flavors:
	-- 1) the order that the bones were listed in the file
	-- 2) the order that the bones were recursed through
	--
	-- #2 is the default, but we can't tell either way at this
	-- stage because that information is in another file (.ani
	-- files specifically -- and in theory different animations
	-- for the same model could use different orderings). So
	-- for now we just keep them cached in both orderings.

	local binBAs = ffi.cast(EQGCommon.BoneAssignmentPtr, data + p)
	p = p + ffi.sizeof(EQGCommon.BoneAssignment) * baCount

	if p > len then tooShort() end

	local weightBuffers = {}

	local function getWeightBuffer(boneIndex)
		local buf = weightBuffers[boneIndex]
		if buf then return buf end
		buf = WeightBuffer.new()
		weightBuffers[boneIndex] = buf
		return buf
	end

	-- bone assignments are per-vertex, need to keep things in
	-- the same order we etracted them earlier
	local vertCounts = {}
	for i = 0, triCount - 1 do
		local tri = tris + i
		local matIndex = tri.materialIndex + 1
		local vertCount = vertCounts[matIndex] or 0

		for j = 0, 2 do
			local binBA = binBAs + tri.index[j]
			for k = 0, binBA.count - 1 do
				local wt = binBA.weights[k]
				local buf = getWeightBuffer(wt.boneIndex + 1)

				buf:addWeight(vertCount + j, matIndex, wt.value)
			end
		end

		vertCounts[matIndex] = vertCount + 3
	end

	-- sort weight buffer arrays for better locality later
	for _, buf in pairs(weightBuffers) do
		buf:sort()
	end

	-- associate weight buffers with bones, by list and by recurse
	local function associateWeights(tbl, type)
		for index, bone in pairs(tbl) do
			local weights = weightBuffers[index]
			if not weights then goto skip end
			bone:setWeightArray(weights, type)
			::skip::
		end
	end

	associateWeights(bonesListOrder, Bone.ListOrder)
	associateWeights(bonesRecurseOrder, Bone.RecurseOrder)

	skele:setBones(bonesListOrder, Skeleton.ListOrder)
	skele:setBones(bonesRecurseOrder, Skeleton.RecurseOrder)

	return skele, p
end

-- single-call extraction for Mod and Ter. Mds is more complicated.
function EQGCommon.extractModel(header, data, len, p, name)
	local strings, materials, sections, tris, skeleton

	strings, p			= EQGCommon.extractStrings(header, data, len, p)
	materials, p		= EQGCommon.extractMaterials(header, strings, data, len, p)
	sections, p, tris	= EQGCommon.extractModelSections(header, header.version, materials, data, len, p)

	if BinUtil.hasField(header[0], "boneCount") and header.boneCount > 0 then
		local bonesLO, bonesRO
		bonesLO, bonesRO, p	= EQGCommon.extractBones(header, strings, data, len, p)
		skeleton, p			= EQGCommon.extractSkeleton(bonesLO, bonesRO, header.vertexCount, tris, header.triangleCount, data, len, p)
	end

	local model = Model.new(name, materials, skeleton)

	model:setMainSubModel(SubModel.new(sections, skeleton))

	return model, p
end

return EQGCommon
