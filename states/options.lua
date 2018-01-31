local state = {}

local backB = sButton("Back", 100, 100, 50, 50, "options", "menu")

function state:new()
	return lovelyMoon.new(self)
end


function state:load()

end


function state:close()
end


function state:enable()

end


function state:disable()

end


function state:update(dt)
end


function state:draw()
	backB:draw()
end

function state:keypressed(key, unicode)

end

function state:keyreleased(key, unicode)

end

function state:mousepressed(x, y, button)
	backB:mousepressed(x, y)
end

function state:mousereleased(x, y, button)
	backB:mousereleased(x, y)
end

return state