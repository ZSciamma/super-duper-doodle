local state = {}

local backB = sButton("Back", 100, 100, 50, 50, "classesList", "menu")

local scroller = ScrollBar()

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
	scroller:update(dt)
end


function state:draw()
	scroller:draw()										-- Must be first so as to be unaffected by the translation
	love.graphics.translate(0, -scroller.y)				-- Makes scroller scroll down the page
	backB:draw()

	for i, class in ipairs(classes) do
		love.graphics.print(class.ClassName, 450, 200 + i * 20)
		love.graphics.print(class.ClassJoinCode, 650, 200 + i * 20)
		love.graphics.print(class.StudentNo, 850, 200 + i * 20)
	end
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

function love.wheelmoved(x, y)
	scroller:wheelmoved(x, y)
end

return state