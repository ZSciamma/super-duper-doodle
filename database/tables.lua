-- This is not made to ever delete accounts. There is no reason to delete students or teachers, and using this fact allows efficiency to be higher.

if love.filesystem.exists("StudentAccountSave") then
	StudentAccount = loadstring(love.filesystem.read("StudentAccountSave"))() 
	StudentMissedEvent = loadstring(love.filesystem.read("StudentMissedEventSave"))()
	TeacherAccount = loadstring(love.filesystem.read("TeacherAccountSave"))() 
	TeacherMissedEvent = loadstring(love.filesystem.read("TeacherMissedEventSave"))()
	Class = loadstring(love.filesystem.read("ClassSave"))() 
	Tournament = loadstring(love.filesystem.read("TournamentSave"))() 
	StudentTournamentGame = loadstring(love.filesystem.read("StudentTournamentGameSave"))()
	TournamentMatch = loadstring(love.filesystem.read("TournamentMatchSave"))() 

else
	StudentAccount = {}
	StudentMissedEvent = {}
	TeacherAccount = {}
	TeacherMissedEvent = {}
	Class = {}
	Tournament = {}
	StudentTournamentGame = {}
	TournamentMatch = {}
end

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

function addTournament(ClassID, MaxDuration, MatchesPerPerson)
	local TournamentNo = #Tournament
	local newTournament = {
		TournamentID = TournamentNo + 1,
		ClassID = ClassID,
		MaxDuration = MaxDuration,
		MatchesPerPerson = MatchesPerPerson,
		StartDate = nil,
		WinnerID = nil
	}
	table.insert(Tournament, newTournament)
	return newTournament.TournamentID
end

function addStudentTournamentGame(StudentID, MatchID, Score)
	local GameNo = FindAvailableID(StudentTournamentGame)
	local newGame = {
		GameID = GameNo + 1,
		StudentID = StudentID,
		MatchID = MatchID,
		Score = nil 					
	}
	table.insert(StudentTournamentGame, newGame)
	return newGame.GameID
end

function addTournamentMatch(StudentMatch1, StudentMatch2, TournamentID)
	local MatchNo = FindAvailableID(TournamentMatch)
	local newMatch = {
		MatchID = MatchNo + 1,
		TournamentID = TournamentID,
		WinnerID = nil
	}
	table.insert(TournamentMatch, newMatch)
	return newMatch.MatchID
end

function FindAvailableID(eventTable)
	local nextID = 1
	for i,event in ipairs(eventTable) do
		if i > nextID then nextID = i end
	end
	return nextID
end

function TournamentWinner(TournamentID, WinnerID)
	for i,T in ipairs(Tournament) do
		if T.TournamentID == TournamentID then
			T.WinnerID = WinnerID
		end
	end
	return 
end

function TeacherClassExists(ClassName, TeacherID)
	for i,j in ipairs(Class) do
		if j.ClassName == ClassName and (not TeacherID or j.TeacherID == TeacherID) then return true end
	end
	return false
end

function ClassTournamentExists(ClassID)
	for i,j in ipairs(Tournament) do
		if j.ClassID == ClassID then 
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

function AddStudentClass(StudentID, ClassID) 		-- Add a student to a class (only once it has been validated)
	for i,student in ipairs(StudentAccount) do
		if StudentID == student.StudentID and not student.ClassID then
			StudentAccount[i].ClassID = ClassID
			return true
		end
	end
	return false
end

function ValidateStudentLogin(EmailAddress, Password)
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

function ValidateTeacherLogin(EmailAddress, Password)
	for i,teacher in ipairs(TeacherAccount) do
		if EmailAddress == teacher.EmailAddress and Password == teacher.Password then
			return teacher.TeacherID
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

function SendTeacherEvents(TeacherID)				-- Return the events missed by the teacher while offline
	local missedEvents = {}
	for i,event in ipairs(TeacherMissedEvent) do
		if event.TeacherID == TeacherID then
			table.insert(missedEvents, event.Message)
		end
	end
	return missedEvents
end

function ClearTeacherEvents(TeacherID)				-- Clear the list of missed events once they have been dealt with
	for i,event in ipairs(TeacherMissedEvent) do
		if event.TeacherID == TeacherID then
			table.remove(TeacherMissedEvent, i)
		end
	end
end

function FetchTeacherInfo(TeacherID)				-- Returns serialized Class, StudentAccount, and Tournament tables, but shortened to include only the classes owned by a specific teacher.
	local classes = {}								-- Consider using aggregate later
	local classIDs = {}
	local students = {}
	local tournaments = {}
	local classNum = 0
	local studentNum = 0
	local tournamentNum = 0

	for i,class in ipairs(Class) do 
		if class.TeacherID == TeacherID then
			classNum = classNum + 1
			classIDs[class.ClassID] = classNum
			table.insert(classes, { ClassID = classNum, ClassName = class.ClassName, JoinCode = class.JoinCode })
		end
	end

	for i,student in ipairs(StudentAccount) do
		if classIDs[student.classID] then
			studentNum = studentNum + 1
			table.insert(students, { StudentID = studentNum, Forename = student.Forename, Surname = student.Surname, Ratings = student.Ratings, ClassID = classIDs[student.ClassID] })
		end
	end

	for i,t in ipairs(Tournament) do
		local num = classIDs[t.ClassID]
		if num then
			tournamentNum = tournamentNum + 1
			table.insert(tournaments, { TournamentID = tournamentNum, ClassName = classes[num].ClassName, MaxDuration = t.MaxDuration, MatchesPerPerson = t.MatchesPerPerson, StartDate = t.StartDate, WinnerID = t.WinnerID})
		end
	end

	return { classes = table.serialize(classes), students = table.serialize(students), tournaments = table.serialize(tournaments) }
end

function FindStudentClassName(StudentID)
	local ClassID = StudentAccount[StudentID].ClassID
	for i,class in ipairs(Class) do
		if class.ClassID == ClassID then
			return class.ClassName
		end
	end
	return false
end

function FindStudentRatings(StudentID)
	return StudentAccount[StudentID].Ratings
end

function StudentInfo(StudentID)
	for i,student in ipairs(StudentAccount) do
		if student.StudentID == StudentID then
			return student
		end
	end
	return false
end





function FindStudentClass(StudentID)
	return StudentAccount[StudentID].ClassID
end

function FindClassID(TeacherID, ClassName)
	for i,j in ipairs(Class) do
		if j.TeacherID == TeacherID and j.ClassName == ClassName then
			return j.ClassID
		end
	end
end

function ValidateTeacherID(TeacherID, Password)		-- Validate teacher details when they come back online
	local teacher = TeacherAccount[TeacherID]
	local debug = TeacherAccount[TeacherID].MissedEvents
	if TeacherID == teacher.TeacherID and Password == teacher.Password then
		return true
	end
	return false
end

function FindTournamentGame(StudentID)
	for i,game in ipairs(StudentTournamentGame) do
		if game.StudentID == StudentID then
			return game.GameID
		end
	end
	return false
end

function FindGameRatings(GameID)
	local ratings = {}
	for i,game in ipairs(StudentTournamentGame) do
		if game.GameID == GameID then 
			local studentID = game.studentID
			table.insert(ratings, StudentAccount[StudentID].Ratings)
		end
	end
	return ratings
end

function UpdateStudentRatings(StudentID, NewStudentRatings) 
	StudentAccount[StudentID].Ratings = NewStudentRatings
end


function ValidateStudentID(StudentID, Password)		-- Validate student details when they come back online
	local student = StudentAccount[StudentID]
	if StudentID == student.StudentID and Password == student.Password then
		return true
	end
	return false
end
