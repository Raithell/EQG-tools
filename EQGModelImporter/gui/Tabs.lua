
local iup			= iup
local setmetatable	= setmetatable

local Tabs = {}
Tabs.__index = Tabs

function Tabs.new()
	local tabs = {
		tabs		= iup.tabs{},
		displayTabs = {},
	}

	tabs.box = iup.hbox{tabs.tabs}

	return setmetatable(tabs, Tabs)
end

function Tabs:add(name, tab)
	local n = #self.displayTabs
	self.tabs["tabtitle" .. n] = name
	iup.Append(self.tabs, tab:getBox())
	self.displayTabs[n + 1] = tab
end

function Tabs:foreach(func)
	local t = self.displayTabs
	for i = 1, #t do func(t[i]) end
end

function Tabs:getBox()
	return self.box
end

return Tabs
