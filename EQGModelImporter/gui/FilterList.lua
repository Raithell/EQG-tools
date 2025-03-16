
local List = require "List"

local iup = iup

local FilterList = {}
FilterList.__index = FilterList
setmetatable(FilterList, List)

function FilterList.new(a)
	local iupFilter = iup.text{
		visiblecolumns	= a.width and a.width - 1 or 15,
		value 			= "",
	}

	local list = List.new(a)

	list.box = iup.vbox{
		iup.hbox{
			iup.label{title = "Filter"},
			iupFilter,
			-----------------------
			alignment	= "ACENTER",
			gap			= 5,
		},
		list:getIupList(),
		-----------------------
		alignment	= "ACENTER",
		gap			= 5,
	}

	list.iupFilter		= iupFilter
	list.unfilteredData = {}

	local invariant	= a.filterInvariant or function() return true end
	local add		= List.add

	iupFilter.valuechanged_cb = function(self)
		local filter = self.value
		if #filter == 0 then
			filter = "."
		else
			filter = filter:gsub("%.", "%%%.")
			if filter:find("%%", -1) then
				filter = filter .. "%"
			end
		end

		local d = list.unfilteredData
		List.clear(list)

		for i = 1, #d do
			local str = d[i]
			if str:find(filter) and invariant(str) then
				add(list, str)
			end
		end

		List.display(list)
	end

	return setmetatable(list, FilterList)
end

function FilterList:add(str)
	local d = self.unfilteredData
	d[#d + 1] = str
end

function FilterList:sort()
	if not self.sorted then return end
	table.sort(self.unfilteredData)
end

function FilterList:remove(pos)
	table.remove(self.unfilteredData, pos)
end

function FilterList:clear()
	List.clear(self)
	self.unfilteredData = {}
end

function FilterList:initialize()
	self:sort()
	self.iupFilter:valuechanged_cb()
end

FilterList.display = FilterList.initialize

function FilterList:getBox()
	return self.box
end

return FilterList
