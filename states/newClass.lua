local state = {}

local backB = sButton("Menu", 100, 100, 50, 50, "newClass", "menu")
local input = textInput(400, 200, 300, 100)
local nextB = sButton("Add Class", love.graphics.getWidth() - 150, 100, 50, 50, "newClass", function() newClass(input.text) end)



function state:new()
	return lovelyMoon.new(self)
end


function state:load()

end


function state:close()
end


function state:enable()
	input:enable()
end


function state:disable()
	input:disable()
end


function state:update(dt)
	input:update(dt)
end


function state:draw()
	backB:draw()
	nextB:draw()
	input:draw()
end

function state:keypressed(key, unicode)
	input:keypressed(key)
end

function state:keyreleased(key, unicode)
	input:keyreleased(key)
end

function state:mousepressed(x, y, button)
	backB:mousepressed(x, y)
	nextB:mousepressed(x, y)
	input:mousepressed(x, y)
end

function state:mousereleased(x, y, button)
	backB:mousereleased(x, y)
	nextB:mousereleased(x, y)
	input:mousereleased(x, y)
end

function newClass(className)
	if className == "" then return end
	ConfirmNewClass(className)
	lovelyMoon.disableState("newClass")
	lovelyMoon.enableState("menu")
end

return state