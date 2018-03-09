-- Not mine (sources given in report):
Object = require 'lib.classic'
require 'lib.tableSer'

-- Mine:
require 'datastructure.linkedList'
require 'datastructure.graph'

require 'database.graph'
require 'database.tables'
require 'comm'
require 'algorithms'



local metaT = getmetatable("")

metaT.__add = function(string1, string2)	--  + 
	return string1.."....."..string2
end

metaT.__mul = function(string1, toAdd)		--  * Adds t after the (i-1)th letter; toAdd = { letter, index }
	local length = string.len(string1)
	return string.sub(string1, 1, toAdd[2] - 1)..toAdd[1]..string.sub(string1, toAdd[2])
end

metaT.__div = function(string1, i)			-- / Removes the ith letter
	local length = string.len(string1)
	return string.sub(string1, 1, i - 1)..string.sub(string1, i + 1)
end

serverTime = 0.1
serverTimer = serverTime
serverLoc = "Localhost:6789"

function love.load()
	love.window.setMode(1100, 600)
	love.graphics.setBackgroundColor(66, 167, 244)

	love.window.setTitle("Interval Server")

	-- Load saved tables for database:

	serv = Server()
end


function love.draw()
	for i,Student in ipairs(StudentAccount) do
		love.graphics.print(Student.Forename, 500, 500 + 15 * i)
	end

	for i,Teacher in ipairs(TeacherAccount) do
		love.graphics.print(Teacher.Forename, 550, 500 + 15 * i)
	end
	serv:draw()
end


function love.update(dt)
	if serverTimer <= 0 then
		serv:update(dt)
		serverTimer = serverTime
	else
		serverTimer = serverTimer - dt
	end
end

function love.quit()					-- Save the tables upon quitting
	love.filesystem.write("StudentAccountSave", table.serialize(StudentAccount))
	love.filesystem.write("StudentMissedEventSave", table.serialize(StudentMissedEvent))
	love.filesystem.write("TeacherAccountSave", table.serialize(TeacherAccount))
	love.filesystem.write("TeacherMissedEventSave", table.serialize(TeacherMissedEvent))
	love.filesystem.write("ClassSave", table.serialize(Class))
	love.filesystem.write("TournamentSave", table.serialize(Tournament))
	love.filesystem.write("TournamentMatchSave", table.serialize(TournamentMatch))
	love.filesystem.write("StudentTournamentGameSave", table.serialize(StudentTournamentGame))
	love.filesystem.write("ScoreboardSave"), table.serialize(Scoreboard)
end