-- This is the template for the buttons for inputting the intervals.

iButton = Object:extend()

neutralColor = { 255, 255, 255 }				-- Usual color
correctColor = { 0, 255, 0 }					-- Color for the correct answer
incorrectColor = { 0, 0, 255 }

radius = 30

function iButton:new(x, y, width, height)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.active = false
end

function iButton:update(dt)

end

function iButton:draw()
	love.graphics.setColor(neutralColor)
	love.graphics.circle("fill", self.x, self.y, radius)
end

function iButton:mousepressed(x, y)
	if x >= self.x and x <= self.x + self.width then
		self.active = true
	end
end

function iButton:mousereleased(x, y)

end