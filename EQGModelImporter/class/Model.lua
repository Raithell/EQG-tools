
local Matrix	= require "Matrix"
local GL		= require "OpenGL"
local Canvas	= require "model/Canvas"

local table			= table
local setmetatable	= setmetatable

local Model = {}
Model.__index = Model

function Model.new(name, materials)
	local model = {
		name		= name,
		materials	= materials,
		alternates	= {},
		viewTrans	= {x = 0, y = 0, z = -2.5},
		viewRot		= {x = 0, y = 0, z = 0},
		viewScale	= 1,
	}
	return setmetatable(model, Model)
end

function Model:updateMatrix()
	local t, r, s = self.viewTrans, self.viewRot, self.viewScale

	self.view = Matrix.translation(t.x, t.y, t.z)
	if self.name:find("^it") then
		self.view = self.view * Matrix.rotY(90) * Matrix.rotZ(90)
		self.matrix = Matrix.rotX(-r.y) * Matrix.rotY(0) * Matrix.rotZ(-r.x) * Matrix.scale(s)
	else
		self.view = self.view * Matrix.rotX(-90) * Matrix.rotZ(-90)
		self.matrix = Matrix.rotX(0) * Matrix.rotY(-r.x) * Matrix.rotZ(-r.y) * Matrix.scale(s)
	end

	--self.projection = Matrix.perspective(45, 300 / 300, 1.0, 10.0)
	self.projection = Matrix.perspective(45, Canvas:getWidth() / Canvas:getHeight(), 1.0, 10.0)
	--self.projection = Matrix.ortho(300, 0, 0, 300, 1.0, 10.0)

	GL.setMatrixUniform(GL.getShader(), "view", self.view:ptr())
	GL.setMatrixUniform(GL.getShader(), "projection", self.projection:ptr())
	GL.setMatrixUniform(GL.getShader(), "model", self.matrix:ptr())
end

function Model:translate(x, y)
	local tx, ty = self.viewTrans.x, self.viewTrans.y
	self.viewTrans.x, self.viewTrans.y = tx - x, ty + y
end

function Model:rotate(x, y)
	local rx, ry = self.viewRot.x, self.viewRot.y
	self.viewRot.x, self.viewRot.y = rx + x, ry + y
end

function Model:scale(diff)
	local scale = self.viewScale - diff
	if scale < 0.1 then scale = 0.1 end
	self.viewScale = scale
end

function Model.setCurrent(model)
	model:updateMatrix()
	Model.cur = model
end

function Model.getCurrent()
	return Model.cur
end

function Model:getName()
	return self.name
end

function Model:setMainSubModel(subModel)
	self.mainSubModel = subModel
end

function Model:addAlternateSubModel(subModel)
	if not self.curAlt then
		self.curAlt = 1
	end
	table.insert(self.alternates, subModel)
end

function Model:allMaterials()
	local i = 0
	return function()
		i = i + 1
		return self.materials[i]
	end
end

function Model:getMaterial(i)
	return self.materials[i]
end

function Model:getMaterialCount()
	return #self.materials
end

function Model:getVertexCount()
	local count = 0
	if self.mainSubModel then
		count = self.mainSubModel:getVertexCount()
	end

	for i = 1, #self.alternates do
		count = count + self.alternates[i]:getVertexCount()
	end
	return count
end

function Model:getTriangleCount()
	return self:getVertexCount() / 3
end

function Model:getBoneCount()
	local skele = self.mainSubModel and self.mainSubModel:getSkeleton()
	if not skele then return 0 end
	return skele:getBoneCount()
end

function Model:setParticles(part)
	self.particleSet = part
end

function Model:draw()
	if self.mainSubModel then
		self.mainSubModel:draw()
	end

	if self.curAlt then
		self.alternates[self.curAlt]:draw()
	end
end

return Model
