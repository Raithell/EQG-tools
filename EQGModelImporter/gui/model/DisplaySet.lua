
local ModelCanvas	= require "model/Canvas"
local TabbedDisplay	= require "TabbedDisplay"
local Spacer		= require "Spacer"

local tabs = TabbedDisplay.new()
--------------------------------
tabs:addTab("Model", require("model/TabModel"))
tabs:addTab("Materials", require("model/TabMaterials"))
--------------------------------

local DisplaySet = {
	tabs = tabs,
}

function DisplaySet:openModel(model)
	ModelCanvas:openModel(model)
	self.tabs:openModel(model)
end

function DisplaySet:clear()
	ModelCanvas:clear()
	self.tabs:clear()
end

DisplaySet.box = iup.hbox{
	ModelCanvas:getBox(),
	Spacer.vertical(5),
	tabs:getBox(),
}

function DisplaySet:getBox()
	return self.box
end

return DisplaySet
