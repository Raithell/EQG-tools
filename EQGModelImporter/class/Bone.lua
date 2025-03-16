
local table			= table
local setmetatable	= setmetatable

local Bone = {
	ListOrder		= "weightsListOrder",
	RecurseOrder	= "weightsRecurseOrder",
}
Bone.__index = Bone

function Bone.new(name, localMatrix)
	local bone = {
		name		= name,
		localMatrix	= localMatrix,
		children 	= {},
	}
	return setmetatable(bone, Bone)
end

function Bone:getName()
	return self.name
end

function Bone:setParent(parent)
	self.parent = parent
	parent:addChild(self)
end

function Bone:addChild(bone)
	table.insert(self.children, bone)
end

function Bone:setLocalMatrix(matrix)
	self.localMatrix = matrix
end

function Bone:getLocalMatrix()
	return self.localMatrix
end

function Bone:setGlobalMatrix(matrix)
	self.globalMatrix = matrix
end

function Bone:getGlobalMatrix()
	return self.globalMatrix
end

function Bone:setWeightArray(array, type)
	self[type] = array
end

function Bone:getWeightArray(type)
	return self[type]
end

return Bone
