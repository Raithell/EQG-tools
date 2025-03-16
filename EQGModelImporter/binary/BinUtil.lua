
local ffi = require "ffi"

ffi.cdef[[
size_t fread(void* ptr, size_t size, size_t count, void* file);
double strtod(const char* str, char** endptr);
int sprintf(char* str, const char* fmt, ...);
]]

local C		= ffi.C
local io	= io
local math	= math

local BinUtil = {
	ByteArray	= ffi.typeof("uint8_t[?]"),
	BytePtr		= ffi.typeof("uint8_t*"),
	CharPtr		= ffi.typeof("char*"),
	Uint32		= ffi.typeof("uint32_t"),
	Uint32Ptr	= ffi.typeof("uint32_t*"),
}

-- turns a 4-character file signature string into a uint32_t
function BinUtil.toSignature(str)
	return ffi.cast(BinUtil.Uint32Ptr, str)[0]
end

-- checks if an arbitrary struct (ref, not ptr) has a field of the given name
function BinUtil.hasField(struct, fieldName)
	return ffi.offsetof(struct, fieldName) ~= nil
end

-- need to undo effect of float -> double extension done by LuaJIT
-- to get nicely-representable original float values
local strtodBuf = ffi.new("char[64]")
function BinUtil.fixFloat(val)
	C.sprintf(strtodBuf, "%g", val)
	return C.strtod(strtodBuf, nil)
end

function BinUtil.sortArray(array, numElements, compFunc, cType)
	local temp = cType()
	local size = ffi.sizeof(cType)

	local function swap(a, b)
		if a == b then return end
		ffi.copy(temp, array[a], size)
		array[a] = array[b]
		array[b] = temp
	end

	local function partition(low, high)
		local pivotIndex = math.floor((low + high) / 2)

		swap(pivotIndex, high)

		local mem = low
		for i = low, high - 1 do
			if compFunc(array[i], array[high]) then
				swap(mem, i)
				mem = mem + 1
			end
		end

		swap(mem, high)
		return mem
	end

	local function quicksort(low, high)
		if low < high then
			local p = partition(low, high)
			quicksort(low, p - 1)
			quicksort(p + 1, high)
		end
	end

	quicksort(0, numElements - 1)
end

function BinUtil.fileRaw(file)
	local n = file:seek("end")
	file:seek("set")
	local data = BinUtil.ByteArray(n)
	C.fread(data, 1, n, file)
	file:close()
	return data, n
end

function BinUtil.openRaw(path)
	local file = assert(io.open(path, "rb"))
	return BinUtil.fileRaw(file)
end

return BinUtil
