
local Grid = require "Grid"

local setmetatable = setmetatable

local PairGrid = {}
PairGrid.__index = PairGrid
setmetatable(PairGrid, Grid)

function PairGrid.new(a)
	a = a or {}
	a.span = 2
	return setmetatable(Grid.new(a), PairGrid)
end

local add = Grid.add
function PairGrid:add(a, b)
	add(self, a)
	add(self, b)
end

return PairGrid
