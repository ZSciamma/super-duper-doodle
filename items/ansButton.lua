-- This is the template for the buttons for answering questions 

ansButton = Object:extend()

neutralColor = { 255, 255, 255 }				-- Usual color
activeColor = { 80, 80, 80 }
correctColor = { 102, 244, 66 }					-- Color for the correct answer
incorrectColor = { 255, 0, 0 }

function ansButton:new(text, x, y, radius)
	self.text = text
	self.x = x
	self.y = y
	self.radius = radius
	self.active = false
	self.on = false								-- The buttons are only 'on' for a short period of time, during which the user can answer questions.	
	self.pressed = false						-- The rest of the time, clicking the buttons will do nothing. By default, the buttons are off.
	self.correct = false						-- True if button was the correct answer AND clicked by the user
	self.incorrect = false						-- True if button was clicked but not the correct answer
end 											

function ansButton:update(dt)

end

function ansButton:draw()
	love.graphics.setColor(neutralColor)
	if self.active then 
		love.graphics.setColor(activeColor)
	end
	if self.correct then
		love.graphics.setColor(correctColor)
	elseif self.incorrect then
		love.graphics.setColor(incorrectColor)
	end

	love.graphics.circle("fill", self.x, self.y, self.radius)
	love.graphics.setColor(0, 0, 0)
	love.graphics.circle("line", self.x, self.y, self.radius)
	love.graphics.print(self.text, self.x, self.y)
end

function ansButton:mousepressed(x, y)
	if math.pow(x - self.x, 2) + math.pow(y - self.y, 2) <= math.pow(self.radius, 2) and self.on then			-- Check that the button can be clicked and that the mouse is on it
		self.active = true
	end
end

function ansButton:mousereleased(x, y)
	if math.pow(x - self.x, 2) + math.pow(y - self.y, 2) <= math.pow(self.radius, 2) and self.on and self.active then	
		self.pressed = true
	end
	self.active = false
end