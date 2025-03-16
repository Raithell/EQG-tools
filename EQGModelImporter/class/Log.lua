
local os 		= os
local string	= string

local file = io.open("log.txt", "w+")

local Log = {}
setmetatable(Log, Log)

function Log.__call(self, ...)
	file:write(...)
	file:write("\n")
end

function Log.close()
	file:close()
end

function Log.time(name, func)
	local c = os.clock()
	func()
	c = os.clock() - c
	file:write(string.format("%s completed in %g seconds.\n", name, c))
end

return Log
