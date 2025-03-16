
local iup = iup

local MainWindow = {}

function MainWindow:init(data)
	self.data		= assert(iup.dialog(data))
	self.base_title = data.title
	self.edited		= false

	function self.data:k_any(key)
		if key == iup.K_ESC then
			return iup.CLOSE
		end
	end

	self.data:show()
	data.loadHook()
	data.loadHook = nil
	iup.MainLoop()
end

function MainWindow:setSubName(name)
	local title = self.base_title .." - ".. name
	if self.edited then
		title = title .. "*"
	end
	self.data.title = title
end

local function toggleEditState(self, edit)
	if self.edited == edit then return end
	if edit then
		self.data.title = self.data.title .. "*"
	else
		self.data.title = self.data.title:sub(1, -2)
	end
	self.edited = edit
end

function MainWindow:edit()
	toggleEditState(self, true)
end

function MainWindow:save()
	toggleEditState(self, false)
end

function MainWindow:isEdited()
	return self.edited
end

return MainWindow
