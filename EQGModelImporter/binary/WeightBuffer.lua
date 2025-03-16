
local ffi		= require "ffi"
local BinUtil	= require "BinUtil"

local setmetatable = setmetatable

local INITIAL_SIZE = 1

ffi.cdef[[
typedef struct VertexWeight {
	int			materialIndex;
	uint32_t	vertexIndex;
	float		weight;
} VertexWeight;
]]

local WeightBuffer = {
	VertexWeight		= ffi.typeof("VertexWeight"),
	VertexWeightArray	= ffi.typeof("VertexWeight[?]"),
}
WeightBuffer.__index = WeightBuffer

function WeightBuffer.new()
	local buf = {
		count	= 0,
		cap		= INITIAL_SIZE,
		array	= WeightBuffer.VertexWeightArray(INITIAL_SIZE),
	}
	return setmetatable(buf, WeightBuffer)
end

local function growArray(self)
	local cap	= self.cap * 2
	local array = WeightBuffer.VertexWeightArray(cap)

	ffi.copy(array, self.array, self.cap * ffi.sizeof(WeightBuffer.VertexWeight))

	self.array	= array
	self.cap	= cap
end

function WeightBuffer:addWeight(vertIndex, matIndex, weight)
	local i = self.count
	self.count = i + 1
	if i == self.cap then
		growArray(self)
	end

	local wt = self.array[i]
	wt.materialIndex	= matIndex
	wt.vertexIndex		= vertIndex
	wt.weight			= weight
end

function WeightBuffer.compare(a, b)
	if a.materialIndex ~= b.materialIndex then
		return a.materialIndex < b.materialIndex
	end
	return a.vertexIndex < b.vertexIndex
end

function WeightBuffer:sort()
	BinUtil.sortArray(self.array, self.count, WeightBuffer.compare, WeightBuffer.VertexWeight)
end

return WeightBuffer
