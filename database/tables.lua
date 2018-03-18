-- This is not made to ever delete accounts. There is no reason to delete students or teachers, and using this fact allows for greater efficiency
-- Very few of the functions here are local as most of them are called from comm.lua


if love.filesystem.exists("StudentAccountSave") then
	StudentAccount = loadstring(love.filesystem.read("StudentAccountSave"))()
	StudentMissedEvent = loadstring(love.filesystem.read("StudentMissedEventSave"))()
	TeacherAccount = loadstring(love.filesystem.read("TeacherAccountSave"))()
	TeacherMissedEvent = loadstring(love.filesystem.read("TeacherMissedEventSave"))()
	Class = loadstring(love.filesystem.read("ClassSave"))()
	Tournament = loadstring(love.filesystem.read("TournamentSave"))()
	Scoreboard = loadstring(love.filesystem.read("ScoreboardSave"))()
	StudentMatch = loadstring(love.filesystem.read("StudentMatchSave"))()
	IncompleteMatch = loadstring(love.filesystem.read("IncompleteMatchSave"))()
else
	StudentAccount = {}
	StudentMissedEvent = {}
	TeacherAccount = {}
	TeacherMissedEvent = {}
	Class = {}
	Tournament = {}
	Scoreboard = {}
	StudentMatch = {}
	IncompleteMatch = {}
end

-- DEBUG:

function printTable(table, NOT) 	-- Useful debugging function for printing a selection of attributes for every record in the table. Kept in because it was useful throughout the development of the program (and would be useful in future additions) and was a key part of the testing
	NOT = NOT or {} 				-- If provided, not is in the format: { ["Rating"] = 0, ["EmailAddress"] = 0, ... } (this example will print every field except Rating and EmailAddress)
	local recordNumber = 0
	print()
	for i,j in ipairs(table) do
		recordNumber = recordNumber + 1
		print("Record Number "..recordNumber..":")
		for k,l in pairs(j) do
			if not NOT[k] then
				print("\t"..k..":"..(string.rep(" ", 15 - string.len(k)))..(l or "nil"))
			end
		end
		print()
	end
end



--***********************************************************************************-
-------------------- CREATE: functions for creating new records

function addStudentAccount(Forename, Surname, EmailAddress, Password, ClassID)
	local StudentNo = #StudentAccount
	local newStudent = {
		StudentID = StudentNo + 1,
		Forename = Forename,
		Surname = Surname,
		EmailAddress = EmailAddress,
		Password = Password,
		ClassID = ClassID,
		Ratings = "0.0.0.0.0.0.0.0.1.1.0.0.1.1.0.0.0.0.0.0.0.0.1.1", 			-- How advanced the student is at the game. Atomic in this case since it is serialized, so as far as the database knows, it is undivisible.
	}
	table.insert(StudentAccount, newStudent)
	return newStudent.StudentID
end

function addStudentMissedEvent(StudentID, Message)
	local EventNumber = FindAvailableID(StudentMissedEvent)
	local newEvent = {
		EventID = EventNumber + 1,
		StudentID = StudentID,
		Message = Message
	}
	table.insert(StudentMissedEvent, newEvent)
	return newEvent.EventNumber
end

function addTeacherAccount(Forename, Surname, EmailAddress, Password)
	local TeacherNo = #TeacherAccount
	local newTeacher = {
		TeacherID = TeacherNo + 1,
		Forename = Forename,
		Surname = Surname,
		EmailAddress = EmailAddress,
		Password = Password,
	}
	table.insert(TeacherAccount, newTeacher)
	return newTeacher.TeacherID
end

function addTeacherMissedEvent(TeacherID, Message)
	local EventNumber = FindAvailableID(TeacherMissedEvent)
	local newEvent = {
		EventID = EventNumber + 1,
		TeacherID = TeacherID,
		Message = Message
	}
	table.insert(TeacherMissedEvent, newEvent)
	return newEvent.EventNumber
end

function addClass(ClassName, TeacherID, JoinCode)
	local ClassNo = #Class
	local newClass = {
		ClassID = ClassNo + 1,
		TeacherID = TeacherID,
		ClassName = ClassName,
		JoinCode = JoinCode
	}
	table.insert(Class, newClass)
	return newClass.ClassID
end

function addTournament(ClassID, RoundTime, QsPerMatch)
	local TournamentNo = #Tournament
	local newTournament = {
		TournamentID = TournamentNo + 1,
		ClassID = ClassID,
		RoundLength = RoundTime,
		QsPerMatch = QsPerMatch,
		LastRound = os.date('*t').yday + 1,				-- The day on which the last round was started. Starts on the day after the tournament is created (the first round is slightly longer to accomodate later creation times (eg. 10pm))
		FinalRanking = nil
	}
	table.insert(Tournament, newTournament)
	return newTournament.TournamentID
end

function addScoreboard(TournamentID, StudentID)
	local ScoreboardNo = #Scoreboard
	local newScoreboard = {
		ScoreboardID = ScoreboardNo + 1,
		StudentID = StudentID,
		TournamentID = TournamentID,
	}
	table.insert(Scoreboard, newScoreboard)
	return
end

function addStudentMatch(FromScoreboardID, ToScoreboardID, QuestionSeed)
	local newStudentMatch = {
		FromScoreboardID = FromScoreboardID,
		ToScoreboardID = ToScoreboardID,
		QuestionSeed = QuestionSeed,
		PointsWon = nil
	}
	table.insert(StudentMatch, newStudentMatch)
end

function addIncompleteMatch(FromScoreboardID, ToScoreboardID, Score)
	local newIncompleteMatch = {
		FromScoreboardID = FromScoreboardID,
		ToScoreboardID = ToScoreboardID,
		Score = Score
	}
	table.insert(IncompleteMatch, newIncompleteMatch)
end


------------------------------
-- Fix these:

function FindAvailableTournamentGameID()
	local nextID = 1
	for i,event in ipairs(TournamentMatch) do
		if event.MatchID > nextID then nextID = event.MatchID end
	end
	return nextID
end


function FindAvailableTournamentGameID()
	local nextID = 1
	for i,event in ipairs(StudentTournamentGame) do
		if event.GameID > nextID then nextID = event.GameID end
	end
	return nextID
end


function FindAvailableID(eventTable)
	local nextID = 1
	for i,event in ipairs(eventTable) do
		if i > nextID then nextID = i end
	end
	return nextID
end



--***********************************************************************************-
-------------------- FETCH:Functions for retreiving information

function TeacherClassExists(ClassName, TeacherID) 	-- Checks whether a teacher already owns a class with this classname. If they do, they can't create another one as every class a teacher has must have a unique classname.
	for i,j in ipairs(Class) do
		if j.ClassName == ClassName and (not TeacherID or j.TeacherID == TeacherID) then return true end
	end
	return false
end

function ClassTournamentExists(ClassID) 	-- Check whether a class is currently in a tournament by iterating through the Tournament table and checking the ClassID of every tournament.
	for i,j in ipairs(Tournament) do
		if j.ClassID == ClassID and j.FinalRanking then
			return true
		end
	end
	return false
end

function EmailTaken(EmailAddress)			-- Check that email teacher or student is using to sign up isn't already in use
	for i,teacher in ipairs(TeacherAccount) do
		if teacher.EmailAddress == EmailAddress then return true end
	end
	for i,student in ipairs(StudentAccount) do
		if student.EmailAddress == EmailAddress then return true end
	end
	return false
end

function ConfirmClassCode(JoinCode)					-- Validate the class code provided by the student to let them join the class, adding them to the class
	for i,class in ipairs(Class) do
		if class.JoinCode == JoinCode then
			return { className = class.ClassName, classID = class.ClassID, teacherID = class.TeacherID }
		end
	end
	return false
end

function ValidateStudentLogin(EmailAddress, Password) 	-- Checks whether a student's login information is valid, returning their StudentID if so.
	for i,student in ipairs(StudentAccount) do
		if EmailAddress == student.EmailAddress and Password == student.Password then
			return student.StudentID
		end
	end
	return false
end

function SendStudentEvents(StudentID)				-- Return the events missed by the student while offline
	local missedEvents = {}
	for i,event in ipairs(StudentMissedEvent) do
		if event.StudentID == StudentID then
			table.insert(missedEvents, event.Message)
		end
	end
	return missedEvents
end

function ValidateTeacherLogin(EmailAddress, Password) -- Checks whether a teacher's login information is valid, returning their TeacherID if valid.
	for i,teacher in ipairs(TeacherAccount) do
		if EmailAddress == teacher.EmailAddress and Password == teacher.Password then
			return teacher.TeacherID
		end
	end
	return false
end

function SendTeacherEvents(TeacherID)				-- Return the events missed by the teacher while offline
	local missedEvents = {}
	for i,event in ipairs(TeacherMissedEvent) do
		if event.TeacherID == TeacherID then
			table.insert(missedEvents, event.Message)
		end
	end
	return missedEvents
end


function FetchTeacherInfo(TeacherID)				-- Returns serialized Class, StudentAccount, and Tournament tables, but shortened to include only the classes owned by a specific teacher.
	-- This is essentially all the information that needs to be stored by the teacher program while they are online (to avoid making constant requests from the server for baskc information)
	-- The teacher database follows a reduced model of the main database.
	local classes = {}								-- Consider using aggregate later
	local classIDs = {}								-- All classes which belong to the teacher
	local students = {}
	local tournaments = {}
	local tournamentNum = 0

	for i,class in ipairs(Class) do
		if class.TeacherID == TeacherID then
			table.insert(classes, { ClassName = class.ClassName, JoinCode = class.JoinCode })
			classIDs[class.ClassID] = class.ClassName 		-- Store the class if it belongs to the teacher
		end
	end

	for i,student in ipairs(StudentAccount) do
		local className = classIDs[student.ClassID]
		if className then
			table.insert(students, { StudentID = student.StudentID, Forename = student.Forename, Surname = student.Surname, Ratings = student.Ratings, ClassName = className })
		end
	end

	for i,t in ipairs(Tournament) do
		local className = classIDs[t.ClassID]
		if className then
			table.insert(tournaments, { TournamentID = tournamentNum, ClassName = className, RoundLength = t.RoundLength, QsPerMatch = t.QsPerMatch, LastRound = t.LastRound, FinalRanking = t.FinalRanking })
			tournamentNum = tournamentNum + 1
		end
	end

	return { classes = table.serialize(classes), students = table.serialize(students), tournaments = table.serialize(tournaments) }
end

function FindStudentClassName(StudentID) 		-- Find a student's ClassName from their StudentID.
	local ClassID = StudentAccount[StudentID].ClassID 	-- Shortcut for finding a student ClassID. This indexing shortcut is widely used throughout the program, based on the principle that no student account is ever deleted (there is no need)
	for i,class in ipairs(Class) do
		if class.ClassID == ClassID then
			return class.ClassName
		end
	end
	return false
end

function FindStudentRatings(StudentID)			-- Returns a student's ratings (ie. how ell they are doing in interval training). Simply here to create a layer between the server and database (ie. layers of validation ensure the server cannot change data directly without calling an appropriate function)
	return StudentAccount[StudentID].Ratings
end

function StudentInfo(StudentID)					-- Returns the entire record for a StudentAccount. Useful for adding a student to a class, for example, when we don't want to have to multiple different records in a row from the same place in the database.
	for i,student in ipairs(StudentAccount) do
		if student.StudentID == StudentID then
			return student
		end
	end
	return false
end

function FindStudentsInClass(classID)		-- Returns the IDs of every student in a class run by a teacher
	local studentIDs = {}
	for i,student in ipairs(StudentAccount) do
		if student.ClassID == classID then
			table.insert(studentIDs, student.StudentID)
		end
	end
	return studentIDs
end

local function classCodeTaken(JoinCode)			-- Check if a specific joinCode has already been assigned
	if JoinCode == "" then return true end		-- JoinCode not yet set, so invalid
	for i,class in ipairs(Class) do
		if Class.JoinCode == JoinCode then
			return true
		end
	end
	return false
end

function FindStudentClass(StudentID)			-- Returns the ID of a student's class
	return StudentAccount[StudentID].ClassID or false
end

function FindClassID(TeacherID, ClassName)		-- Returns the ID of a class belonging to a teacher, given the name of the class
	for i,j in ipairs(Class) do
		if j.TeacherID == TeacherID and j.ClassName == ClassName then
			return j.ClassID
		end
	end
	return false
end

function FindTournamentRoundStart(TournamentID)			-- Returns the time allowed for each round of matches in a tournament to be completed
	for i,t in ipairs(Tournament) do
		if t.TournamentID == TournamentID then
			return t.LastRound
		end
	end
	return false
end

--***********************************************************************************-
-------------------- UPDATE: Functions for adding to information in tables

function AddStudentClass(StudentID, ClassID) 		-- Add a student to a class (only once it has been validated)
	for i,student in ipairs(StudentAccount) do
		if StudentID == student.StudentID and not student.ClassID then
			StudentAccount[i].ClassID = ClassID
			return true
		end
	end
	return false
end

function ClearStudentEvents(StudentID)				-- Clear the list of missed events once they have been dealt with
	for i,event in ipairs(StudentMissedEvent) do
		if event.StudentID == StudentID then
			table.remove(StudentMissedEvent, i)
		end
	end
end

function ClearTeacherEvents(TeacherID)				-- Clear the list of missed events once they have been dealt with
	for i,event in ipairs(TeacherMissedEvent) do
		if event.TeacherID == TeacherID then
			table.remove(TeacherMissedEvent, i)
		end
	end
end

function GenerateClassJoinCode()			-- Generates a random code to be associated with a class. It also checks the code is unique, so we don't end up with two classes with the same joinCode (however improbable that may be)
	local code = ""
	while classCodeTaken(code) do
		for i = 1, 7 do
			code = code..tostring(love.math.random(1, 9))
		end
	end
	return code
end

function UpdateStudentRatings(StudentID, NewStudentRatings) 	-- Replace the current student ratings with the new ones (sent by the student program)
	StudentAccount[StudentID].Ratings = NewStudentRatings
end
