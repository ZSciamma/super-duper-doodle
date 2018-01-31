-- This file is for algorithms - functions which calculate results to be sent back to the teacher or student.
-- Examples are tournament matching and generating random codes for classes.

function generateClassJoinCode()			-- Generates a random code to be associated with a class. Make these unique. 
	local code = ""
	for i = 1, 6 do
		code = code..tostring(love.math.random(0, 9))
	end
	return code
end
