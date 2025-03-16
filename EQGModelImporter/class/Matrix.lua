
local ffi = require "ffi"

----------------------------
--  0,  4,  8, 12
--  1,  5,  9, 13
--  2,  6, 10, 14
--  3,  7, 11, 15
----------------------------

ffi.cdef[[
typedef struct Matrix {
	float m[16];
} Matrix;
]]

local mat4 = ffi.typeof("Matrix")

local function identity()
	local m = mat4()
	m.m[0]	= 1
	m.m[5]	= 1
	m.m[10]	= 1
	m.m[15]	= 1
	return m
end

local Matrix = {}
Matrix.__index = Matrix

Matrix.identity = identity

function Matrix:copy()
	local copy = mat4()
	ffi.copy(copy, self, ffi.sizeof(mat4))
	return copy
end

function Matrix.translation(x, y, z)
	local m = identity()
	m.m[12] = x or 0
	m.m[13] = y or 0
	m.m[14] = z or 0
	return m
end

local function cosSin(angle)
	local rad = math.rad(angle)
	return math.cos(rad), math.sin(rad)
end

function Matrix.rotX(angle)
	local mat = identity()
	local m = mat.m
	local cos, sin = cosSin(angle)

	m[5]  = cos
	m[6]  = sin
	m[9]  = -sin
	m[10] = cos

	return mat
end

function Matrix.rotY(angle)
	local mat = identity()
	local m = mat.m
	local cos, sin = cosSin(angle)

	m[0]  = cos
	m[2]  = -sin
	m[8]  = sin
	m[10] = cos

	return mat
end

function Matrix.rotZ(angle)
	local mat = identity()
	local m = mat.m
	local cos, sin = cosSin(angle)

	m[0] = cos
	m[1] = sin
	m[4] = -sin
	m[5] = cos

	return mat
end

function Matrix.scale(x, y, z)
	local mat = identity()
	local m = mat.m
	m[0]  = x
	m[5]  = y or x
	m[10] = z or x
	return mat
end

function Matrix:ptr()
	return self.m
end

function Matrix.__mul(a, b)
	local mat = mat4()
	local m = mat.m
	a, b = a.m, b.m

	m[0] = a[0]*b[0] + a[4]*b[1] + a[8]*b[2]  + a[12]*b[3]
	m[1] = a[1]*b[0] + a[5]*b[1] + a[9]*b[2]  + a[13]*b[3]
	m[2] = a[2]*b[0] + a[6]*b[1] + a[10]*b[2] + a[14]*b[3]
	m[3] = a[3]*b[0] + a[7]*b[1] + a[11]*b[2] + a[15]*b[3]

	m[4] = a[0]*b[4] + a[4]*b[5] + a[8]*b[6]  + a[12]*b[7]
	m[5] = a[1]*b[4] + a[5]*b[5] + a[9]*b[6]  + a[13]*b[7]
	m[6] = a[2]*b[4] + a[6]*b[5] + a[10]*b[6] + a[14]*b[7]
	m[7] = a[3]*b[4] + a[7]*b[5] + a[11]*b[6] + a[15]*b[7]

	m[8]  = a[0]*b[8] + a[4]*b[9] + a[8]*b[10]  + a[12]*b[11]
	m[9]  = a[1]*b[8] + a[5]*b[9] + a[9]*b[10]  + a[13]*b[11]
	m[10] = a[2]*b[8] + a[6]*b[9] + a[10]*b[10] + a[14]*b[11]
	m[11] = a[3]*b[8] + a[7]*b[9] + a[11]*b[10] + a[15]*b[11]

	m[12] = a[0]*b[12] + a[4]*b[13] + a[8]*b[14]  + a[12]*b[15]
	m[13] = a[1]*b[12] + a[5]*b[13] + a[9]*b[14]  + a[13]*b[15]
	m[14] = a[2]*b[12] + a[6]*b[13] + a[10]*b[14] + a[14]*b[15]
	m[15] = a[3]*b[12] + a[7]*b[13] + a[11]*b[14] + a[15]*b[15]

	return mat
end

-- transposed, technically
function Matrix.fromQuaternion(q)
	local mat = mat4()
	local m = mat.m

	m[0]  = 1.0 - 2.0 * q.y * q.y - 2.0 * q.z * q.z
	m[4]  = 2.0 * q.x * q.y + 2.0 * q.z * q.w
	m[8]  = 2.0 * q.x * q.z - 2.0 * q.y * q.w

	m[1]  = 2.0 * q.x * q.y - 2.0 * q.z * q.w
	m[5]  = 1.0 - 2.0 * q.x * q.x - 2.0 * q.z * q.z
	m[9]  = 2.0 * q.z * q.y + 2.0 * q.x * q.w

	m[2]  = 2.0 * q.x * q.z + 2.0 * q.y * q.w
	m[6]  = 2.0 * q.z * q.y - 2.0 * q.x * q.w
	m[10] = 1.0 - 2.0 * q.x * q.x - 2.0 * q.y * q.y

	m[15] = 1.0

	return mat
end

function Matrix.perspective(fovy, aspectRatio, near, far)
	fovy = math.rad(fovy) -- degrees to radians

	local tanHalfFoVy = math.tan(fovy / 2.0)

	local mat = mat4()
	local m = mat.m

	m[0]  = 1.0 / (aspectRatio * tanHalfFoVy)
	m[5]  = 1.0 / tanHalfFoVy
	m[10] = -(far + near) / (far - near)
	m[14] = -1.0
	m[11] = -(2.0 * far * near) / (far - near)

	return mat
end

function Matrix.ortho(right, left, top, bot, near, far)
	local mat = mat4()
	local m = mat.m

	m[0]  = 2.0 / (right - left)
	m[5]  = 2.0 / (top - bot)
	m[10] = -2.0 / (far - near)
	m[3]  = -(right + left) / (right - left)
	m[7]  = -(top + bot) / (top - bot)
	m[11] = -(far + near) / (far - near)

	return mat
end

ffi.metatype(mat4, Matrix)

return Matrix
