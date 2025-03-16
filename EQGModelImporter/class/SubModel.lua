
--------------------------------------------------------------------------------
-- SubModel.lua
--
-- Groups ModelSections together into a complete part of a Model.
--
-- Conceptually different from a Model in that a Model can have separate and
-- alternate "head" SubModels in addition to the main SubModel.
--------------------------------------------------------------------------------

local pairs			= pairs
local setmetatable	= setmetatable

local SubModel = {}
SubModel.__index = SubModel

function SubModel.new(sections, skeleton, name)
	local sm = {
		sections	= sections,
		skeleton	= skeleton,
		name		= name, -- only exists for Mds model parts
	}
	for k, section in pairs(sections) do
		section:init()
	end
	return setmetatable(sm, SubModel)
end

function SubModel:getVertexCount()
	local count = 0
	for k, section in pairs(self.sections) do
		count = count + section:getVertexCount()
	end
	return count
end

function SubModel:getSkeleton()
	return self.skeleton
end

function SubModel:draw()
	for k, section in pairs(self.sections) do
		section:draw()
	end
end

return SubModel
