
local PairGrid		= require "PairGrid"
local TitledList	= require "TitledList"
local Spacer		= require "Spacer"
local Model			= require "Model"
local Material		= require "Material"
local Property		= require "Property"

local pairs = pairs

local grid = PairGrid.new()

local TabMaterials = {
	matList = TitledList.new{
		title = "Material List",
		width = 10,
	},
	propList = TitledList.new{
		title = "Property List",
		width = 8,
	},
	grid = grid,
}

local fields = {
	shader		= iup.text{visiblecolumns = 12}, -- change to dropdown box
	propValue	= iup.text{visiblecolumns = 12},
}

----------------------
grid:add("Material Shader", fields.shader)
grid:add("Property Value", fields.propValue)
grid:setLongestLine(1)
----------------------

function TabMaterials:openModel(model)
	local list = self.matList

	list:clear()

	for mat in model:allMaterials() do
		list:add(mat:getName())
	end

	list:display()
end

function TabMaterials:clear()
	self.matList:clear()
	self.propList:clear()
	for _, field in pairs(fields) do
		field.value = ""
	end
end

TabMaterials.matList:onSelected(function(str, pos)
	local model	= Model.getCurrent()
	local mat	= model:getMaterial(pos)
	local list	= TabMaterials.propList

	Material.setCurrent(mat)
	fields.shader.value = mat:getShader()
	fields.propValue.value = ""

	list:clear()

	for prop in mat:allProperties() do
		list:add(prop:getName())
	end

	list:display()
end)

TabMaterials.propList:onSelected(function(str, pos)
	local mat	= Material.getCurrent()
	local prop	= mat:getProperty(pos)

	Property.setCurrent(prop)
	fields.propValue.value = prop:getRepresentation()
end)

TabMaterials.box = iup.hbox{
	TabMaterials.matList:getBox(),
	Spacer.vertical(5),
	TabMaterials.propList:getBox(),
	Spacer.vertical(5),
	iup.vbox{
		Spacer.horizontal(8),
		grid:getBox(),
	},
}

function TabMaterials:getBox()
	return self.box
end

return TabMaterials
