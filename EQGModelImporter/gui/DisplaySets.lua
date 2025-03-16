
local Model = require "Model"

local iup = iup

local DisplaySets = {
	box			= iup.zbox{},
	contained	= {},
	----------------------
	Model		= "model",
	Zone		= "zone",
}

function DisplaySets:init()
	self:show(DisplaySets.Model)
	self.init = nil
end

function DisplaySets:add(name, display)
	self.contained[name] = display
	iup.Append(self.box, display:getBox())
end

function DisplaySets:show(name)
	local display	= self.contained[name]
	self.box.value	= display and display:getBox() or nil
	self.cur		= display
	return display
end

function DisplaySets:openModel(model)
	if not self.cur then return end
	Model.setCurrent(model)
	self.cur:openModel(model)
end

function DisplaySets:clear()
	if not self.cur then return end
	self.cur:clear()
end

function DisplaySets:getBox()
	return self.box
end

--------------------------------------
DisplaySets:add(DisplaySets.Model, require("model/DisplaySet"))
--------------------------------------

return DisplaySets
