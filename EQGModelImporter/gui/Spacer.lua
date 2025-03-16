
local iup = iup

local Spacer = {}

function Spacer.vertical(n)
	return iup.vbox{nmargin = n .."x0"}
end

function Spacer.horizontal(n)
	return iup.hbox{nmargin = "0x".. n}
end

return Spacer
