
local GL		= require "OpenGL"
local Texture	= require "Texture"

local table			= table
local setmetatable	= setmetatable

local Material = {}
Material.__index = Material

function Material.new(name, shader, s3d)
	local mat = {
		name		= name,
		shader		= shader,
		s3d			= s3d,
		properties	= {},
	}
	return setmetatable(mat, Material)
end

function Material.setCurrent(mat)
	Material.cur = mat
end

function Material.getCurrent()
	return Material.cur
end

function Material:getName()
	return self.name
end

function Material:getShader()
	return self.shader
end

function Material:addProperty(prop)
	table.insert(self.properties, prop)
end

function Material:getProperty(i)
	return self.properties[i]
end

function Material:getPropertyByName(name)
	for prop in self:allProperties() do
		if prop:getName() == name then
			return prop
		end
	end
end

function Material:allProperties()
	local i = 0
	return function()
		i = i + 1
		return self.properties[i]
	end
end

function Material:getDiffuseTexture()
	local tex = self.diffuseTexture
	if tex then return tex end

	local prop = self:getPropertyByName("e_TextureDiffuse0")
	if not prop then return Texture.getDefault() end

	local name = prop:getValue()
	tex = Texture.new(self.s3d, name) or Texture.getDefault()

	self.diffuseTexture = tex
	return tex
end

return Material
