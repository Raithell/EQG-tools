
local ffi = require "ffi"

ffi.cdef[[
int glGetError();
const char* glGetString(int enumid);
void glEnable(int enumid);

void glBlendFunc(int sfactor, int dfactor);

void glLoadIdentity();
void glClear(uint32_t bitfield);
void glClearColor(float r, float g, float b, float a);
void glMatrixMode(uint32_t bitfield);
void glViewport(int	x, int y, uint32_t w, uint32_t h);
void glPixelZoom(float x, float y);
void glDrawPixels(uint32_t w, uint32_t h, int32_t bit_a, int32_t bit_b, void* pixels);

/* Texture */
void glGenTextures(uint32_t n, uint32_t* textures_out);
void glBindTexture(int textype, uint32_t id);
void glTexParameteri(int textype, int param, int value);
void glGenerateMipmap(int textype);
void glTexImage2D(int target, int level, int ifmt, uint32_t w, uint32_t h, int border, int fmt, int type, const void* data);

/* Drawing functions */
void glDrawArrays(int enumid, int firstIndex, uint32_t vertCount);
void glDrawElements(int enumid, uint32_t count, int type, const void* indices);
]]

local lib = ffi.load(ffi.os == "Windows" and "opengl32" or "GL")

local GL = {
	VERSION					= 0x1F01,
	--------------
	TRIANGLES				= 0x0004,
	--------------
	BYTE					= 0x1400,
	UNSIGNED_BYTE			= 0x1401,
	SHORT					= 0x1402,
	UNSIGNED_SHORT			= 0x1403,
	INT						= 0x1404,
	UNSIGNED_INT			= 0x1405,
	FLOAT					= 0x1406,
	DOUBLE					= 0x140A,
	--------------
	TEXTURE_2D				= 0x0DE1,
	TEXTURE_MAG_FILTER		= 0x2800,
	TEXTURE_MIN_FILTER		= 0x2801,
	TEXTURE_WRAP_S			= 0x2802,
	TEXTURE_WRAP_T			= 0x2803,
	NEAREST					= 0x2600,
	LINEAR					= 0x2601,
	REPEAT					= 0x2901,
	MIRRORED_REPEAT			= 0x8370,
	CLAMP_TO_EDGE			= 0x812F,
	CLAMP_TO_BORDER			= 0x812D,
	--------------
	COLOR_BUFFER_BIT		= 0x4000,
	DEPTH_BUFFER_BIT		= 0x0100,
	DEPTH_TEST				= 0x0B71,
	TEXTURE					= 5890,
	BLEND					= 0x0BE2,
	SRC_ALPHA				= 0x0302,
	ONE_MINUS_SRC_ALPHA		= 0x0303,
	BGRA					= 0x80E1,
	ARRAY_BUFFER			= 0x8892,
	ELEMENT_ARRAY_BUFFER	= 0x8893,
	--------------
	STATIC_DRAW				= 0x88E4,
	DYNAMIC_DRAW			= 0x88E8,
	STREAM_DRAW				= 0x88E0,
	--------------
	FRAGMENT_SHADER			= 0x8B30,
	VERTEX_SHADER			= 0x8B31,
	COMPILE_STATUS			= 0x8B81,
}

local dyn = {}
local dynLoad

if ffi.os == "Windows" then
	ffi.cdef "void* wglGetProcAddress(const char* name);"
	function dynLoad(name, sig)
		dyn[name] = ffi.cast(sig, lib.wglGetProcAddress(name))
	end
else
	ffi.cdef "void* glXGetProcAddress(const char* name);"
	function dynLoad(name, sig)
		dyn[name] = ffi.cast(sig, lib.glXGetProcAddress(name))
	end
end

local vertShader = [[
#version 150 core

in vec3 position;
in vec2 texCoord;
out vec2 uvCoord;
uniform mat4 model;
uniform mat4 projection;
uniform mat4 view;

void main()
{
	uvCoord = texCoord;
	gl_Position = projection * view * model * vec4(position, 1.0);
}
]]

local fragShader = [[
#version 150 core

in vec2 uvCoord;
uniform float alpha;
uniform sampler2D texture;

void main()
{
	vec4 pixel = texture2D(texture, uvCoord);
	gl_FragColor = vec4(pixel.xyz, alpha);
}
]]

function GL.contextCreated()
	local ptrBindDelete = ffi.typeof("void(*)(uint32_t)")
	local ptrProgShader = ffi.typeof("void(*)(uint32_t, uint32_t)")

	dynLoad("glGenVertexArrays", "void(*)(int, uint32_t*)")
	dynLoad("glBindVertexArray", ptrBindDelete)
	dynLoad("glGenBuffers", "void(*)(uint32_t, uint32_t*)")
	dynLoad("glBindBuffer", "void(*)(int, uint32_t)")
	dynLoad("glBufferData", "void(*)(int, intptr_t, const void*, int)")

	dynLoad("glCreateShader", "uint32_t(*)(int)")
	dynLoad("glDeleteShader", ptrBindDelete)
	dynLoad("glShaderSource", "void(*)(uint32_t, uint32_t, const char**, const int*)")
	dynLoad("glCompileShader", ptrBindDelete)
	dynLoad("glGetShaderiv", "void(*)(uint32_t, int, int*)")
	dynLoad("glGetShaderInfoLog", "void(*)(uint32_t, uint32_t, void*, char*)")

	dynLoad("glCreateProgram", "uint32_t(*)()")
	dynLoad("glDeleteProgram", ptrBindDelete)
	dynLoad("glAttachShader", ptrProgShader)
	dynLoad("glDetachShader", ptrProgShader)
	dynLoad("glLinkProgram", ptrBindDelete)
	dynLoad("glUseProgram", ptrBindDelete)

	dynLoad("glGetAttribLocation", "uint32_t(*)(uint32_t, const char*)")
	dynLoad("glEnableVertexAttribArray", ptrBindDelete)
	dynLoad("glVertexAttribPointer", "void(*)(uint32_t, int, int, int, uint32_t, const void*)")
	dynLoad("glBindFragDataLocation", "void(*)(uint32_t, uint32_t, const char*)")

	dynLoad("glGetUniformLocation", "uint32_t(*)(uint32_t, const char*)")
	dynLoad("glUniformMatrix4fv", "void(*)(uint32_t, int, int, const void*)")
	dynLoad("glUniform1f", "void(*)(int, float)")

	GL.enableDepth()
	GL.enableTransparency()

	local vshader = GL.createShader("vertex")
	GL.shaderSource(vshader, vertShader)
	GL.compileShader(vshader)

	local fshader = GL.createShader("fragment")
	GL.shaderSource(fshader, fragShader)
	GL.compileShader(fshader)

	GL.shader = GL.createProgram()
	GL.attachShader(GL.shader, vshader)
	GL.attachShader(GL.shader, fshader)
	GL.linkProgram(GL.shader)
	GL.useProgram(GL.shader)
end

function GL.getShader()
	return GL.shader
end

local defaultTexture = ffi.new("uint8_t[4]", 0xFF, 0xFF, 0xFF, 0xFF)
function GL.getDefaultTexture()
	return defaultTexture
end

function GL.getVersionString()
	local str = lib.glGetString(GL.VERSION)
	if str == nil then
		error("getVersionString: ".. lib.glGetError())
	end
	return ffi.string(str)
end

function GL.enableDepth()
	lib.glEnable(GL.DEPTH_TEST)
end

function GL.enableTransparency()
	lib.glEnable(GL.BLEND)
	lib.glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
end

function GL.loadIdentity()
	lib.glLoadIdentity()
end

function GL.clear(v)
	lib.glClear(v)
end

function GL.clearColor(r, g, b, a)
	lib.glClearColor(r, g, b, a)
end

function GL.matrixMode(v)
	lib.glMatrixMode(v)
end

function GL.viewport(x, y, w, h)
	lib.glViewport(x, y, w, h)
end

function GL.pixelZoom(x, y)
	lib.glPixelZoom(x, y)
end

function GL.drawPixels(w, h, va, vb, pixels)
	lib.glDrawPixels(w, h, va, vb, pixels)
end

----------------------------------------
-- VERTEX ARRAY
----------------------------------------
local uint32Array = ffi.typeof("uint32_t[?]")
function GL.genVertexArrays(n)
	local out = uint32Array(n)
	dyn.glGenVertexArrays(n, out)
	return out
end

function GL.bindVertexArray(vao)
	dyn.glBindVertexArray(vao)
end

----------------------------------------
-- VERTEX BUFFER
----------------------------------------
function GL.genBuffers(n)
	local out = uint32Array(n)
	dyn.glGenBuffers(n, out)
	return out
end

function GL.bindBuffer(buffer)
	dyn.glBindBuffer(GL.ARRAY_BUFFER, buffer)
end

function GL.bufferData(data, len)
	dyn.glBufferData(GL.ARRAY_BUFFER, len, data, GL.STATIC_DRAW)
end

function GL.bindIndexBuffer(buffer)
	dyn.glBindBuffer(GL.ELEMENT_ARRAY_BUFFER, buffer)
end

function GL.indexData(data, len)
	dyn.glBufferData(GL.ELEMENT_ARRAY_BUFFER, len, data, GL.STATIC_DRAW)
end

----------------------------------------
-- SHADER
----------------------------------------
function GL.createShader(type)
	return dyn.glCreateShader(type:lower() == "vertex" and GL.VERTEX_SHADER or GL.FRAGMENT_SHADER)
end

function GL.deleteShader(shader)
	dyn.glDeleteShader(shader)
end

local strArray = ffi.typeof("const char*[1]")
function GL.shaderSource(shader, str)
	local array = strArray()
	array[0] = str
	dyn.glShaderSource(shader, 1, array, nil)
end

local status = ffi.new("int[1]")
local errbuf = ffi.new("char[512]")
function GL.compileShader(shader)
	dyn.glCompileShader(shader)
	dyn.glGetShaderiv(shader, GL.COMPILE_STATUS, status)

	if status[0] == 1 then return end
	dyn.glGetShaderInfoLog(shader, 512, nil, errbuf)
	error(ffi.string(errbuf))
end

----------------------------------------
-- SHADER PROGRAM
----------------------------------------
function GL.createProgram()
	return dyn.glCreateProgram()
end

function GL.attachShader(program, shader)
	dyn.glAttachShader(program, shader)
end

function GL.detachShader(program, shader)
	dyn.glDetachShader(program, shader)
end

function GL.linkProgram(program)
	dyn.glLinkProgram(program)
end

function GL.useProgram(program)
	dyn.glUseProgram(program)
end

function GL.setVertexAttrib(program, varname, size, stride, offset)
	local id = dyn.glGetAttribLocation(program, varname)
	dyn.glEnableVertexAttribArray(id)
	dyn.glVertexAttribPointer(id, size, GL.FLOAT, 0, stride or 0, offset and ffi.cast("void*", offset) or nil)
end

function GL.bindFragDataLocation(program, varname)
	dyn.glBindFragDataLocation(program, 0, varname)
end

function GL.deleteProgram(program)
	dyn.glDeleteProgram(program)
end

----------------------------------------
-- TEXTURE
----------------------------------------

function GL.genTextures(n)
	local out = uint32Array(n)
	lib.glGenTextures(n, out)
	return out
end

function GL.bindTexture(tex)
	lib.glBindTexture(GL.TEXTURE_2D, tex)
end

local wrap = {
	["repeat"]		= GL.REPEAT,
	mirroredrepeat	= GL.MIRRORED_REPEAT,
	clamptoedge		= GL.CLAMP_TO_EDGE,
	clamptoborder	= GL.CLAMP_TO_BORDER,
}
function GL.textureWrap(type)
	local t = wrap[type:lower()] or GL.CLAMP_TO_BORDER
	lib.glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, t)
	lib.glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, t)
end

function GL.textureFilter(type)
	local t = type:lower() == "linear" and GL.LINEAR or GL.NEAREST
	lib.glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, t)
	lib.glTexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, t)
end

function GL.textureImage(width, height, data)
	lib.glTexImage2D(GL.TEXTURE_2D, 0, 0x1908, width, height, 0, GL.BGRA, GL.UNSIGNED_BYTE, data)
end

function GL.generateMipmaps()
	lib.glGenerateMipmap(GL.TEXTURE_2D)
end

----------------------------------------
-- MATRIX
----------------------------------------

function GL.setMatrixUniform(program, varname, ptr)
	local id = dyn.glGetUniformLocation(program, varname)
	dyn.glUniformMatrix4fv(id, 1, 0, ptr)
end

function GL.setFloatUniform(program, varname, val)
	local id = dyn.glGetUniformLocation(program, varname)
	dyn.glUniform1f(id, val)
end

----------------------------------------
-- DRAW
----------------------------------------

function GL.drawActiveArray(numVertices)
	lib.glDrawArrays(GL.TRIANGLES, 0, numVertices)
end

function GL.drawActiveIndices(numIndices)
	lib.glDrawElements(GL.TRIANGLES, numIndices, GL.UNSIGNED_INT, nil)
end

return GL
