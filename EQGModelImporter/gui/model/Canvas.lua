
local GL	= require "OpenGL"
local Util	= require "Util"

local iup = iup

local Canvas = {
	canvas = iup.glcanvas{
		buffer		= "DOUBLE",
		rastersize	= "300x300",
	},

	width	= 300,
	height	= 300,
}

function Canvas.canvas:action()
	iup.GLMakeCurrent(self)

	GL.clearColor(0.25, 0.25, 0.25, 1.0)
	GL.clear(GL.COLOR_BUFFER_BIT + GL.DEPTH_BUFFER_BIT)

	local model = Canvas.model
	if model then model:draw() end

	iup.GLSwapBuffers(self)
end

function Canvas.canvas:resize_cb(width, height)
	Canvas.width = width
	Canvas.height = height
	GL.viewport(0, 0, width, height)

	if Canvas.model then
		Canvas.model:updateMatrix()
		Canvas:draw()
	end
end

function Canvas:getWidth()
	return self.width
end

function Canvas:getHeight()
	return self.height
end

local mouseDown = {}
function Canvas.canvas:button_cb(button, pressed, x, y, status)
	local down = (pressed == 1)

	if button == iup.BUTTON1 then -- left mouse button
		mouseDown.left = down
		mouseDown.rotX, mouseDown.rotY = Util.getCursorPos()
	elseif button == iup.BUTTON3 then -- right mouse button
		mouseDown.right = down
		mouseDown.transX, mouseDown.transY = Util.getCursorPos()
	elseif button == iup.BUTTON2 then -- middle mouse button
		mouseDown.middle = down
		mouseDown.zoomX = Util.getCursorPos()
	end
end

function Canvas:openModel(model)
	self.model = model
	self:draw()

	if self.timer then iup.Destroy(self.timer) end

	self.timer = iup.timer{
		time		= 10,
		run			= "NO",
		action_cb	= function()
			local changed

			if mouseDown.left then
				local rx, ry = Util.getCursorPos()
				model:rotate((mouseDown.rotY - ry) * 0.25, (mouseDown.rotX - rx) * 0.25)
				mouseDown.rotX, mouseDown.rotY = rx, ry
				changed = true
			end

			if mouseDown.right then
				local cx, cy = Util.getCursorPos()
				model:translate((mouseDown.transX - cx) * 0.005, (mouseDown.transY - cy) * 0.005)
				mouseDown.transX, mouseDown.transY = cx, cy
				changed = true
			end

			if mouseDown.middle then
				local x = Util.getCursorPos()
				local zoom = (mouseDown.zoomX - Util.getCursorPos()) * 0.005
				model:scale(zoom)
				mouseDown.zoomX = x
				changed = true
			end

			if changed then
				model:updateMatrix()
				Canvas:draw()
			end
		end,
	}

	self.timer.run = "YES"
end

function Canvas:clear()
	if self.timer then
		iup.Destroy(self.timer)
		self.timer = nil
	end
	self.model = nil
	iup.Update(self.canvas)
end

function Canvas:draw()
	iup.Update(self.canvas)
end

function Canvas:getBox()
	return self.canvas
end

return Canvas
