-- This is the file defining the scrollbar item (used for scrolling through a list, for example)

ScrollBar = Object:extend()

local barColour = { 150, 150, 150 }
local barWidth = 20
local barHeight = love.graphics.getHeight()
local barX = love.graphics.getWidth() - barWidth
local barY = 0

function ScrollBar:new()	
	self.width = 15				-- Dimensions for the scrollable rectangle
	self.height = 50
	self.x = love.graphics.getWidth() - 17		-- Place scroller in middle of rectangle    alternately: - ((barWidth + self.width) / 2)	
	self.y = 0

	self.vX = 0					-- Velocities
	self.vY = 0
	self.accel = 10				-- How much speed the scrollbar gains depending on the user's motion
	self.deccel = 20			-- How mcuh speed the scrollbar loses

end

function ScrollBar:update(dt)
	-- Move the bar if onscreen:
	if self.y >= -1 and self.vY < 0 or self.y + self.height <= love.graphics.getHeight() + 50 and self.vY > 0 then
		self.y = self.y + self.vY * dt
	end

	-- Keep the bar onscreen:
	if self.y < 0 then self.y = 0 end
	if self.y + self.height > love.graphics.getHeight() then self.y = love.graphics.getHeight() - self.height end
	
	-- Slow down the bar without movement:
	if self.vY > 0 then
		self.vY = self.vY - self.deccel * math.min(1, 10 * dt)
		if self.vY < 0 then self.vY = 0 end
	elseif self.vY < 0 then
		self.vY = self.vY + self.deccel * math.min(1, 10 * dt)
		if self.vY > 0 then self.vY = 0 end
	end
end

function ScrollBar:draw()
	love.graphics.setColor(barColour)
	love.graphics.rectangle("fill", love.graphics.getWidth() - barWidth, barY, barWidth, barHeight)
	love.graphics.setColor(80, 80, 80)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

end

function ScrollBar:wheelmoved(x, y)
	self.vY = self.vY + y * self.accel
end