-- This file is for algorithms - functions which calculate results to be sent back to the teacher or student.
-- Examples are tournament matching and generating random codes for classes.

function generateClassJoinCode()			-- Generates a random code to be associated with a class. Make these unique. 
	local code = ""
	while ClassCodeTaken(code) do
		for i = 1, 7 do
			code = code..tostring(love.math.random(0, 9))
		end
	end
	return code
end
