
--------------------------------------------------------------------------------
-- ModelSection.lua
--
-- Associates a VertexBuffer with the Material used to render it.
--------------------------------------------------------------------------------

local GL		= require "OpenGL"
local Texture	= require "Texture"

local setmetatable = setmetatable

local ModelSection = {}
ModelSection.__index = ModelSection

function ModelSection.new(vertBuffer, material)
	local sec = {
		vertexBuffer	= vertBuffer,
		material		= material,
	}

	return setmetatable(sec, ModelSection)
end

function ModelSection:init()
	-- init opengl structures
	self.vao = GL.genVertexArrays(1)[0]
	GL.bindVertexArray(self.vao)
	local buf = GL.genBuffers(2)
	self.vbo = buf[0]
	self.idx = buf[1]
	GL.bindBuffer(self.vbo)
	GL.bindIndexBuffer(self.idx)

	local shader = GL.getShader()
	GL.useProgram(shader)
	-- struct Vertex { float [x, y, z], i, j, k, [u, v]; }
	GL.setVertexAttrib(shader, "position", 3, 8 * 4)
	GL.setVertexAttrib(shader, "texCoord", 2, 8 * 4, 6 * 4)
	GL.setFloatUniform(shader, "alpha", 1.0)

	self.texture = GL.genTextures(1)[0]
	GL.bindTexture(self.texture)
	GL.textureFilter("linear")
	GL.textureWrap("mirroredRepeat")

	self.indexCount = self.vertexBuffer:getIndexCount()
	GL.bufferData(self.vertexBuffer:getVertexArray(), self.vertexBuffer:getVertexArraySize())
	GL.indexData(self.vertexBuffer:getIndexArray(), self.vertexBuffer:getIndexArraySize())

	local tex = self.material and self.material:getDiffuseTexture() or Texture.getDefault()
	GL.textureImage(tex:getWidth(), tex:getHeight(), tex:getPixelArray())
end

function ModelSection:getVertexCount()
	return self.vertexBuffer:getVertexCount()
end

function ModelSection:draw()
	GL.bindVertexArray(self.vao)
	GL.bindTexture(self.texture)
	GL.drawActiveIndices(self.indexCount)
end

return ModelSection
