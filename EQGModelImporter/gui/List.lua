
local iup 		= iup
local table		= table
local tonumber	= tonumber

local List = {}
List.__index = List

function List.new(a)
	local iupList = iup.list{
		visiblelines	= a.lines or 10,
		visiblecolumns	= a.width or 16,
		dropdown		= a.dropdown and "YES" or "NO",
		multiselect		= a.multiselect and "YES" or "NO",
		expand			= a.noexpand and "NO" or "VERTICAL",
		dropfilestarget	= a.dragdrop and "YES" or "NO",
		sort			= "NO",
		autoredraw		= "YES",
	}

	local list = {
		iupList 	= iupList,
		listData	= {},
		sorted		= a.sorted,
	}

	return setmetatable(list, List)
end

function List:add(str)
	local d = self.listData
	d[#d + 1] = str
end

function List:sort()
	if not self.sorted then return end
	table.sort(self.listData)
end

function List:clear()
	self.listData = {}
	self.iupList[1] = nil
	self.value = nil
end

function List:getSelection()
	local v = tonumber(self.iupList.value)
	if not v or v == 0 then return false end
	return self.listData[v], v
end

function List:remove(pos)
	table.remove(self.listData, pos)
end

function List:display()
	local list	= self.iupList
	local d 	= self.listData

	list[1] = nil
	list.autoredraw = "NO"

	for i = 1, #d do
		list[i] = d[i]
	end

	list[#d + 1] = nil

	list.autoredraw = "YES"
end

function List:onSelected(func)
	self.iupList.action = function(self, str, pos, state)
		if state == 1 then
			func(str, pos)
		end
	end
end

function List:onRightClick(func)
	self.iupList.button_cb = function(self, button, pressed, x, y)
		if button == iup.BUTTON3 and pressed == 0 then
			func(x, y)
		end
	end
end

function List:onFileDrop(func)
	self.iupList.dropfiles_cb = function(self, path, n)
		func(path, n)
	end
end

function List:getIupList()
	return self.iupList
end

return List
