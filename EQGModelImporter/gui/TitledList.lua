
local List = require "List"

local iup = iup

local TitledList = {}
TitledList.__index = TitledList
setmetatable(TitledList, List)

function TitledList.new(a)
	local list = List.new(a)

	list.box = iup.vbox{
		iup.hbox{
			iup.label{title = a.title or "Untitled"},
			-----------------------
			alignment	= "ACENTER",
			gap			= 5,
		},
		list:getIupList(),
		-----------------------
		alignment	= "ACENTER",
		gap			= 5,
	}

	return setmetatable(list, TitledList)
end

function TitledList:getBox()
	return self.box
end

return TitledList
