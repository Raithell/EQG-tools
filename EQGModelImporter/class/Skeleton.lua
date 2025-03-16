
local setmetatable = setmetatable

local Skeleton = {
	ListOrder		= "bonesListOrder",
	RecurseOrder	= "bonesRecurseOrder",
}
Skeleton.__index = Skeleton

function Skeleton.new()
	return setmetatable({}, Skeleton)
end

function Skeleton:setBones(bones, type)
	self[type] = bones
end

function Skeleton:getBoneCount()
	return #self[Skeleton.ListOrder]
end

return Skeleton
