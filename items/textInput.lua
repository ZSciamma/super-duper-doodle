textInput = Object:extend()

local pointerTime = 0.6					-- How much time pointer stays onscreen
local pointerHeight = 15
local letterWidth = 7
local iBeamCursor = love.mouse.getSystemCursor("ibeam")
local arrowCursor = love.mouse.getSystemCursor("arrow")
local pointerMargin = 5
local shiftsPressed = 0					-- Number of shift keys currently pressed
local placeHolderText = "Enter Class Code"

function textInput:new(x, y, width, height)
	self.on = true 						-- Is the field enabled?
	self.x = x
	self.y = y
	self.width = width
	self.height = height												
	self.pointery0 = self.y + (self.height - pointerHeight) / 2		-- Place pointer in middle of field
	self.pointerx0 = self.x + pointerMargin
	self:reset()
end

function textInput:reset()
	self.on = false
	self.text = ""							-- The text entered by the user
	self.active = false						-- True if the user clicked it and has not yet released		
	self.pressed = false					-- True if the user is writing something		
	self.pointerIndex = 0					-- How many letters in is the pointer?				
	self.hover = false
	self.pointerIsVis = true				-- Is the text pointer visible?		
	self.pointerTimer = 0
	shiftsPressed = 0
end

function textInput:update(dt)
	if not self.on then return end

	local mouseX = love.mouse.getX()
	local mouseY = love.mouse.getY()
	if mouseX >= self.x and mouseX <= self.x + self.width + self.width and mouseY >= self.pointery0 and mouseY <= self.pointery0 + pointerHeight then
		if not self.hover then
			love.mouse.setCursor(iBeamCursor)
			self.hover = true
		end
	elseif self.hover then
		love.mouse.setCursor(arrowCursor)
		self.hover = false
	end

	-- Place pointer below mouse (only in allowed positions):
	if self.active then
		if mouseX <= self.pointerx0 then
			self.pointerIndex = 0
		elseif mouseX >= self.pointerx0 + string.len(self.text) * letterWidth then		
			self.pointerIndex = string.len(self.text)
		else
			self.pointerIndex = math.round((mouseX - self.pointerx0) / letterWidth)				-- Place pointer in nearest available position
		end
	end

	-- Toggle pointer visibility every second:
	if self.pressed then self.pointerTimer = self.pointerTimer - dt end
	if self.pointerTimer <= 0 then
		self.pointerTimer = pointerTime
		self.pointerIsVis = not self.pointerIsVis
	end 
end

function textInput:draw()
	if not self.on then return end

	-- Draw box:
	love.graphics.setColor(177, 177, 205)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)	-- Eventually make this a polygon to have rounded corners

	love.graphics.setColor(255, 255, 255)
	love.graphics.rectangle("fill", self.x + 3, self.pointery0 - 5, self.width - 6, pointerHeight + 10)			-- Magic numbers for slight adjustment
	love.graphics.setColor(0, 0, 0)
	if self.pressed then love.graphics.setColor(255, 0, 0) end
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)	-- Is this really necessary?
	love.graphics.setColor(0, 0, 0)
	if self.pressed then
		--love.graphics.rectangle("line", self.x, self.pointery0 - 5, self.width, pointerHeight + 10)
	end

	-- Draw pointer:
	if self.pressed and self.pointerIsVis then
		local pointerXPos = self.pointerx0 + self.pointerIndex * letterWidth
		love.graphics.line(pointerXPos, self.pointery0, pointerXPos, self.pointery0 + pointerHeight)
	end

	-- Print text:
	love.graphics.print(self.text, self.pointerx0, self.pointery0 + 2)

	if string.len(self.text) == 0 then
		love.graphics.setColor(177, 177, 205)
		love.graphics.print(placeHolderText, self.pointerx0, self.pointery0 + 2)
	end
end

function textInput:mousepressed(x, y)		
	if not self.on then return end

	if x >= self.x and x <= self.x + self.width and y >= self.pointery0 and y <= self.pointery0 + pointerHeight then
		self.active = true
		self.pressed = true
	else
		self.pressed = false
	end
end

function textInput:mousereleased(x, y)
	if not self.on then return end

	self.active = false
	if self.pressed then
		self.pointerTimer = pointerTime
		self.pointerIsVis = true
	end
end

function textInput:keypressed(key)
	if not self.on then return end

	if key == "lshift" or key == "rshift" then 
		shiftsPressed = shiftsPressed + 1
	elseif not self.pressed then return 
	elseif key == "return" then self:enter() 
	elseif key == "rctrl" or key == "lctrl" then return 
	elseif key == "backspace" then
		if self.pointerIndex <= 0 then return end
		self.text = self.text / self.pointerIndex
		self.pointerIndex = self.pointerIndex - 1
		-- remove text before pointer
	elseif key == "right" then
		if self.pointerIndex >= string.len(self.text) then return end
		self.pointerIndex = self.pointerIndex + 1
	elseif key == "left" then
		if self.pointerIndex <= 0 then return end
		self.pointerIndex = self.pointerIndex - 1
	elseif key == "up" then self.pointerIndex = 0 return
	elseif key == "down" then self.pointerIndex = string.len(self.text) return
	else 
		if key == "space" then key = " " end
		if shiftsPressed > 0 then key = string.upper(key) end
		self.text = self.text * { key, self.pointerIndex + 1 }
		self.pointerIndex = self.pointerIndex + 1
	end
end

function textInput:keyreleased(key)
	if not self.on then return end

	if key == "lshift" or key == "rshift" then
		shiftsPressed = shiftsPressed - 1
	end
end

function textInput:enter()
	if not self.on then return end

	self.pressed = false
	-- Validate it and send it the database
	local text = self.text
	self:reset()
	self.on = true
	return self.text
end

function textInput:disable()
	self:reset()
end

function textInput:enable()
	self.on = true
end

function math.round(number)
	return math.floor(number + 0.5)
end


-- Any text in the text input is considered 'entered'. The user only has to click the 'next' button on the page to confirm text entry