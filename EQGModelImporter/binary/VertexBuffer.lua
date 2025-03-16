
local ffi = require "ffi"

local setmetatable = setmetatable

local INITIAL_SIZE = 32

ffi.cdef[[
/* binary compatible with pre-V3 EQG vertices */
typedef struct Vertex {
	float x, y, z;	// position
	float i, j, k;	// normal
	float u, v;		// texture coordinates
} Vertex;

typedef uint32_t Index;
]]

local VertexBuffer = {
	Vertex		= ffi.typeof("Vertex"),
	VertexPtr	= ffi.typeof("Vertex*"),
	VertexArray	= ffi.typeof("Vertex[?]"),
	Index		= ffi.typeof("Index"),
	IndexPtr	= ffi.typeof("Index*"),
	IndexArray	= ffi.typeof("Index[?]"),
}
VertexBuffer.__index = VertexBuffer

function VertexBuffer.new()
	local buf = {
		vertexCount	= 0,
		vertexCap	= INITIAL_SIZE,
		vertices	= VertexBuffer.VertexArray(INITIAL_SIZE),
		indexCount	= 0,
		indexCap	= INITIAL_SIZE,
		indices		= VertexBuffer.IndexArray(INITIAL_SIZE),
	}
	return setmetatable(buf, VertexBuffer)
end

function VertexBuffer:getVertexCount()
	return self.vertexCount
end

function VertexBuffer:getIndexCount()
	return self.indexCount
end

function VertexBuffer:getVertexArray()
	return self.vertices
end

function VertexBuffer:getIndexArray()
	return self.indices
end

function VertexBuffer:getVertexArraySize()
	return self.vertexCount * ffi.sizeof(VertexBuffer.Vertex)
end

function VertexBuffer:getIndexArraySize()
	return self.indexCount * ffi.sizeof(VertexBuffer.Index)
end

local function growArrays(self)
	local cap	= self.vertexCap * 2
	local vbuf	= VertexBuffer.VertexArray(cap)
	local ibuf	= VertexBuffer.IndexArray(cap)

	ffi.copy(vbuf, self.vertices, self.vertexCap * ffi.sizeof(VertexBuffer.Vertex))
	ffi.copy(ibuf, self.indices, self.indexCap * ffi.sizeof(VertexBuffer.Index))

	self.vertices	= vbuf
	self.indices	= ibuf

	self.vertexCap	= cap
	self.indexCap	= cap
end

local function checkSize(self)
	local i = self.vertexCount
	self.vertexCount = i + 1
	self.indexCount	= i + 1
	if i == self.vertexCap then
		growArrays(self)
	end
	return i
end

function VertexBuffer:addVertex(src)
	local i = checkSize(self)
	local dst = self.vertices + i

	-- need to swap y and z for OpenGL
	dst.x, dst.y, dst.z = src.x, src.y, src.z
	dst.i, dst.j, dst.k = src.i, src.k, src.j
	dst.u, dst.v        = src.u, src.v

	self.indices[i] = i
end

return VertexBuffer
