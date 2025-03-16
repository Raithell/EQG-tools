
package.path  = "class/?.lua;binary/?.lua;gui/?.lua"
package.cpath = "dll/?.dll"

local MainWindow	= require "MainWindow"
local Settings		= require "Settings"
local Menu			= require "Menu"
local Spacer		= require "Spacer"
local FileList		= require "FileList"
local ModelList		= require "ModelList"
local DisplaySets	= require "DisplaySets"
local Log			= require "Log"
local GL			= require "OpenGL"

_G.Log = Log

local menu = Menu.new()
-----------------------
local sub = menu:addSubMenu("&File")
sub:addItem("Set EQG Search Folder", Settings.setS3DFolder)
sub:addSeparator()
sub:addItem("&Quit", function() return iup.CLOSE end)
-----------------------

Settings:init(FileList.listCallback)
FileList:init(ModelList.listCallback)

MainWindow:init{
	iup.hbox{
		FileList:getBox(),
		Spacer.vertical(5),
		ModelList:getBox(),
		Spacer.vertical(5),
		DisplaySets:getBox(),
		-----------------
		nmargin = "10x10",
	},
	menu	= menu:getIupMenu(),
	title	= "EQG Model Importer v1.0",
	---------------------
	loadHook = function()
		Settings:load()
		DisplaySets:init()
		GL.contextCreated()
	end,
}
