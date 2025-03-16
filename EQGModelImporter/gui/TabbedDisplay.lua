
local Tabs = require "Tabs"

local setmetatable = setmetatable

local TabbedDisplay = {}
TabbedDisplay.__index = TabbedDisplay

function TabbedDisplay.new()
	local td = {
		tabs = Tabs.new(),
	}
	return setmetatable(td, TabbedDisplay)
end

function TabbedDisplay:addTab(name, tab)
	tab:getBox().nmargin = "5x5"
	self.tabs:add(name, tab)
end

function TabbedDisplay:openModel(model)
	self.tabs:foreach(function(t)
		t:openModel(model)
	end)
end

function TabbedDisplay:clear()
	self.tabs:foreach(function(t)
		t:clear()
	end)
end

function TabbedDisplay:getBox()
	return self.tabs:getBox()
end

return TabbedDisplay
