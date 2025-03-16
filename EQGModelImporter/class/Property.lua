
local string		= string
local setmetatable	= setmetatable

local Property = {
	Float	= "float",
	String	= "string",
	Color	= "color",
}
Property.__index = Property

function Property.new(name)
	local prop = {
		name = name,
	}
	return setmetatable(prop, Property)
end

function Property.setCurrent(prop)
	Property.cur = prop
end

function Property.getCurrent()
	return Property.cur
end

function Property:getName()
	return self.name
end

function Property:setValueFloat(val)
	self.valueType		= Property.Float
	self.representation	= val
	self.value			= val
end

function Property:setValueString(str)
	self.valueType		= Property.String
	self.representation	= str
	self.value			= str
end

function Property:setValueColor(int, c)
	self.valueType		= Property.Color
	self.representation	= string.format("RGBA #%0.2x%0.2x%0.2x%0.2x", c.r, c.g, c.b, c.a)
	self.value			= int
end

function Property:getRepresentation()
	return self.representation
end

function Property:getValue()
	return self.value
end

return Property
