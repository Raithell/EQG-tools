
local PairGrid = require "PairGrid"

local grid = PairGrid.new()

local TabModel = {
	grid = grid,
}

local fields = {
	name		= iup.text{visiblecolumns = 12, readonly = "YES"},
	matCount	= iup.text{visiblecolumns = 12, readonly = "YES"},
	vertCount	= iup.text{visiblecolumns = 12, readonly = "YES"},
	triCount	= iup.text{visiblecolumns = 12, readonly = "YES"},
	boneCount	= iup.text{visiblecolumns = 12, readonly = "YES"},
}

----------------------
grid:add("Name", fields.name)
grid:add("Materials", fields.matCount)
grid:add("Vertices", fields.vertCount)
grid:add("Triangles", fields.triCount)
grid:add("Bones", fields.boneCount)
grid:setLongestLine(4)
----------------------

function TabModel:openModel(model)
	fields.name.value		= model:getName()
	fields.matCount.value	= model:getMaterialCount()
	fields.vertCount.value	= model:getVertexCount()
	fields.triCount.value	= model:getTriangleCount()
	fields.boneCount.value	= model:getBoneCount()
end

function TabModel:clear()
	for _, field in pairs(fields) do
		field.value = ""
	end
end

TabModel.box = iup.vbox{
	grid:getBox(),
}

function TabModel:getBox()
	return self.box
end

return TabModel
