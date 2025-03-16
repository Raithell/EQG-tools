
local Util = require "Util"

local FILENAME = "settings.txt"

local iup		= iup
local type		= type
local rawget	= rawget
local rawset	= rawset

local Settings = {
	pathFunc	= Util.nullFunc,
	values		= {},
}

local function tolower(k)
	if type(k) == "string" then
		return k:lower()
	end
	return k
end

local mt = {
	__index = function(t, k)
		return rawget(t, tolower(k))
	end,

	__newindex = function(t, k, v)
		rawset(t, tolower(k), v)
	end,
}

setmetatable(Settings.values, mt)

function Settings:init(pathFunc)
	self.pathFunc = pathFunc
	self.init = nil
end

function Settings.setS3DFolder()
	local self = Settings
	local path = Util.getDirectory{title = "Select EQG Search Folder"}
	if not path then return end

	self.pathFunc(path)
	self:set("S3DFolder", path)
	return path
end

function Settings.getS3DFolder()
	local self = Settings
	local path = self:get("S3DFolder")
	if path then return path end

	return self.setS3DFolder()
end

function Settings:get(key)
	return self.values[key]
end

function Settings:set(key, value, save)
	self.values[key] = value
	if save or save == nil then self:save() end
end

function Settings:save()
	local file = assert(io.open(FILENAME, "w+"))
	file:write[[
---------------------------------
-- EQG Model Importer Settings --
---------------------------------

]]

	for k, v in pairs(self.values) do
		local t = type(v)
		if t == "string" then
			v = '"' .. (v:gsub("\\", "\\\\")) .. '"'
		end
		file:write(k, " = ", v, "\n")
	end
end

function Settings:load()
	local f = loadfile(FILENAME)
	if not f then
		return self.setS3DFolder()
	end

	setfenv(f, self.values)
	pcall(f)

	local path = self:get("S3DFolder")
	if not path then return end

	self.pathFunc(path)
	self.load = nil
end

return Settings
