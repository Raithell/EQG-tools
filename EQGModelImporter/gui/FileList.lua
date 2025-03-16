
local lfs			= require "lfs"
local Menu			= require "Menu"
local FilterList	= require "FilterList"
local S3D			= require "S3D"
local DisplaySets	= require "DisplaySets"

local FileList = {
	filterList = FilterList.new{
		sorted			= true,
		width			= 12,
		filterInvariant	= function(str) return str:find("%.eqg$") end,
	},

	dirPath = "",
}

function FileList:init(selectCallback)
	self.selectionCallback = selectCallback
end

function FileList.listCallback(path)
	FileList.dirPath = path
	local list = FileList.filterList

	list:clear()

	for str in lfs.dir(path) do
		list:add(str)
	end

	list:initialize()
end

FileList.filterList:onSelected(function(str)
	DisplaySets:clear()
	local path = FileList.dirPath .."/".. str
	local s3d = S3D.open(path)

	FileList.selectionCallback(s3d)

	FileList.curS3D = s3d
end)

function FileList:getBox()
	return self.filterList:getBox()
end

return FileList
