-- Not mine (sources given in report):
Object = require 'lib.classic'
require 'lib.tableSer'

-- Mine:
require 'datastructures.queue'
require 'datastructures.linkedList'
require 'datastructures.graph'

require 'database.tables'
require 'database.tournaments'
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

local serverTime = 0.1
local serverTimer = serverTime
local dateTime = os.date('*t')				-- Stores the current date and time
local lastYDay = dateTime.yday 					-- The last day (of the year) on which each tournament was checked (to see if every match was finished)

serverLoc = "Localhost:6789"
TournamentMatchesChecked = false			-- Checks whether the program has checked every tournament to see if its last round has finished yet today


function love.load()						-- Callback function called upon loading the program
	love.window.setMode(1100, 600)
	love.graphics.setBackgroundColor(66, 167, 244)

	love.window.setTitle("Interval Server")

	-- Load saved tables for database:

	serv = Server()
end


function love.draw()						-- Callback function called after update(): draws everything onscreen
	for i,Student in ipairs(StudentAccount) do
		love.graphics.print(Student.Forename, 500, 500 + 15 * i)
	end

	for i,Teacher in ipairs(TeacherAccount) do
		love.graphics.print(Teacher.Forename, 550, 500 + 15 * i)
	end
	serv:draw()
end


function love.update(dt)					-- Callback function called every dt milliseconds
	dateTime = os.date('*t')
	if (dateTime.yday ~= lastYDay) then
		CheckTournamentRoundsFinished(dateTime)
		lastYDay = dateTime.yday
	end

	if serverTimer <= 0 then
		serv:update(dt)
		serverTimer = serverTime
	else
		serverTimer = serverTimer - dt
	end
end

function love.quit()						-- Callback function called when the user quits (by pressing 'X' or otherwise)				
	-- Save the tables upon quitting
	love.filesystem.write("StudentAccountSave", table.serialize(StudentAccount))
	love.filesystem.write("StudentMissedEventSave", table.serialize(StudentMissedEvent))
	love.filesystem.write("TeacherAccountSave", table.serialize(TeacherAccount))
	love.filesystem.write("TeacherMissedEventSave", table.serialize(TeacherMissedEvent))
	love.filesystem.write("ClassSave", table.serialize(Class))
	love.filesystem.write("TournamentSave", table.serialize(Tournament))
	love.filesystem.write("ScoreboardSave", table.serialize(Scoreboard))
	love.filesystem.write("StudentMatchSave", table.serialize(StudentMatch))
	love.filesystem.write("IncompleteMatchSave", table.serialize(IncompleteMatch))
end

-- Incomplete match: stores results for any match which only one of the two players has finished so far.
-- Reason for not putting ProvisionalScore in database: the table is updated pretty frequently, so it wouldn't be convenient
-- to keep in the StudentMatch table. Furthermore, it wouldn't be in 3NF, since the PointsWon would have a transive dependency,
-- and it's much more useful to keep the points won for ease of access and creation of the tournament graph in the future than
-- the provisional score.