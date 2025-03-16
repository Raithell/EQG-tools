
local BinUtil	= require "BinUtil"
local FreeImage	= require "FreeImage"
local GL		= require "OpenGL"
local ffi		= require "ffi"

local setmetatable = setmetatable

local Texture = {}
Texture.__index = Texture

function Texture.new(s3d, name)
	local data, len = s3d:getEntryByName(name:lower())
	if not data then return end

	local img, fmtID, fmtName = FreeImage.open(data, len)

	local tex = {
		pixelArray	= FreeImage.getPixelBuffer(img),
		width		= FreeImage.getWidth(img),
		height		= FreeImage.getHeight(img),
		img			= ffi.gc(img, FreeImage.close),
	}

	return setmetatable(tex, Texture)
end

function Texture.getDefault()
	local def = Texture.default
	if def then return def end

	def = {
		pixelArray	= GL.getDefaultTexture(),
		width		= 1,
		height		= 1,
	}

	Texture.default = def

	return setmetatable(def, Texture)
end

function Texture:getWidth()
	return self.width
end

function Texture:getHeight()
	return self.height
end

function Texture:getPixelArray()
	return self.pixelArray
end

return Texture
