
local Menu			= require "Menu"
local FilterList	= require "FilterList"
local Mod			= require "Mod"
local Mds			= require "Mds"
local DisplaySets	= require "DisplaySets"
local ParticleSet	= require "ParticleSet"

local pcall = pcall

local ModelList = {
	filterList = FilterList.new{
		sorted	= true,
		width	= 12,
	},

	modelFileList = {},
}

function ModelList.listCallback(s3d)
	ModelList.curS3D = s3d
	local list = ModelList.filterList
	local models = ModelList.modelFileList

	list:clear()

	for name in s3d:fileNames() do
		if name:find("%.mod$") or name:find("%.mds$") or name:find("%.ter$") then
			local displayName = name:match("[^%.]+")
			models[displayName] = name
			list:add(displayName)
		end
	end

	list:initialize()
end

ModelList.filterList:onSelected(function(str)
	local fileName = ModelList.modelFileList[str]
	local ext = fileName:match("%.(.+)$")
	local s3d = ModelList.curS3D

	ModelList.curModelFileName = fileName

	local data, len = s3d:getEntryByName(fileName)

	--pcall(function()
		local model

		if ext == "mod" then
			model = Mod.open(data, len, str)
		elseif ext == "mds" then
			model = Mds.open(data, len, str)
		elseif ext == "ter" then

		end

		if model then
			model:setParticles(ParticleSet.open(s3d, str))
			DisplaySets:openModel(model)
		end
	--end)
end)

function ModelList:getBox()
	return self.filterList:getBox()
end

return ModelList
