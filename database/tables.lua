-- This is not made to ever delete accounts. There is no reason to delete students or teachers, and using this fact allows efficiency to be higher.

if love.filesystem.exists("StudentAccountSave") then
	StudentAccount = loadstring(love.filesystem.read("StudentAccountSave"))() 
	TeacherAccount = loadstring(love.filesystem.read("TeacherAccountSave"))() 
	Class = loadstring(love.filesystem.read("ClassSave"))() 
	Tournament = loadstring(love.filesystem.read("TournamentSave"))() 
	TournamentMatch = loadstring(love.filesystem.read("TournamentMatchSave"))()
	StudentMatch = loadstring(love.filesystem.read("StudentMatchSave"))() 
else
	StudentAccount = {}
	TeacherAccount = {}
	Class = {}
	Tournament = {}
	TournamentMatch = {}
	StudentMatch = {}

end

function addStudentAccount(Forename, Surname, EmailAddress, Password, ClassName)
	local StudentNo = #StudentAccount
	local newStudent = {
		StudentID = StudentNo + 1,
		Forename = Forename,
		Surname = Surname,
		EmailAddress = EmailAddress,
		Password = Password,
		ClassName = ClassName,
		Level = "01234456", 					-- How advanced the student is at the game
		MissedEvents = {}
	}
	table.insert(StudentAccount, newStudent)
	return newStudent.StudentID
end

function addTeacherAccount(Forename, Surname, EmailAddress, Password)
	local TeacherNo = #TeacherAccount
	local newTeacher = {
		TeacherID = TeacherNo + 1,
		Forename = Forename,
		Surname = Surname,
		EmailAddress = EmailAddress,
		Password = Password,
		MissedEvents = {}
	}
	table.insert(TeacherAccount, newTeacher)
	return newTeacher.TeacherID
end

function addClass(ClassName, TeacherID, JoinCode)
	local ClassNo = #Class
	local newClass = {
		ClassName = ClassName,
		ClassID = ClassNo + 1,
		TeacherID = TeacherID,
		JoinCode = JoinCode
	}
	table.insert(Class, newClass)
	return newClass.ClassID
end

function addStudentMatch(StudentID, TournamentID)
	local MatchNo = #StudentMatch
	local newMatch = {
		StudentMatchID = MatchNo + 1,
		StudentID = StudentID,
		TournamentID = TournamentID
	}
	table.insert(StudentMatch, newMatch)
	return newMatch.StudentMatchID
end

function addTournamentMatch(StudentMatch1, StudentMatch2, TournamentID)
	local MatchNo = #TournamentMatch
	local newMatch = {
		MatchID = MatchNo + 1,
		StudentMatch1 = StudentMatch1,
		StudentMatch2 = StudentMatch2,
		TournamentID = TournamentID
	}
	table.insert(TournamentMatch, newMatch)
	return newMatch.MatchID
end

function addTournament(ClassName, MaxDuration, Matches)
	local TournamentNo = #Tournament
	local newTournament = {
		TournamentID = TournamentNo + 1,
		ClassName = ClassName,
		MaxDuration = MaxDuration,
		Matches = Matches,
		StartDate = 0
	}
	table.insert(Tournament, newTournament)
	return newTournament.TournamentID
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

function TeacherTournamentExists(ClassName, TeacherID)
	for i,j in ipairs(Tournament) do
		if j.ClassName == ClassName then 
			return true 
		end
	end
	return false
end

function EmailTaken(EmailAddress)			-- Check that email teacher or student is using to sign up isn't already in use		
	for i,teacher in ipairs(TeacherAccount) do
		if teacher.EmailAddress == EmailAddress then return true end
	end
	for i,j in ipairs(StudentAccount) do
		if j.EmailAddress == EmailAddress then return true end
	end
	return false
end

function ConfirmClassCode(JoinCode)					-- Validate the class code provided by the student to let them join the class
	for i,class in ipairs(Class) do
		if class.JoinCode == JoinCode then 
			return { className = class.ClassName, TeacherID = class.TeacherID }
		end
	end
	return ""
end

function ValidateStudentID(StudentID, Password)		-- Validate student details when they come back online
	local student = StudentAccount[StudentID]
	if StudentID == student.StudentID and Password == student.Password then
		return true
	end
	return false
end

function FindStudentClass(StudentID)
	return StudentAccount[StudentID].ClassName
end

function ValidateTeacherID(TeacherID, Password)		-- Validate teacher details when they come back online
	local teacher = TeacherAccount[TeacherID]
	local debug = TeacherAccount[TeacherID].MissedEvents
	if TeacherID == teacher.TeacherID and Password == teacher.Password then
		return true
	end
	return false
end

function AddStudentEvent(StudentID, Event)			-- Add an event to be sent to the student when they come back online
	table.insert(StudentAccount[StudentID].MissedEvents, Event)
end

function AddTeacherEvent(TeacherID, Event)			-- Add an event to be sent to the teacher when they come back online
	table.insert(TeacherAccount[TeacherID].MissedEvents, Event)
end

function SendStudentEvents(StudentID)				-- Return the events missed by the student while offline
	return StudentAccount[StudentID].MissedEvents
end

function SendTeacherEvents(TeacherID)				-- Return the events missed by the teacher while offline
	return TeacherAccount[TeacherID].MissedEvents
end

function ClearStudentEvents(StudentID)				-- Clear the list of missed events once they have been dealt with
	StudentAccount[StudentID].MissedEvents = {}
end

function ClearTeacherEvents(TeacherID)				-- Clear the list of missed events once they have been dealt with
	TeacherAccount[TeacherID].MissedEvents = {} 
end

function FindTournamentMatch(StudentID)
	for i,j in ipairs(TournamentMatch) do
		if j.StudentMatch1 == StudentID or j.StudentMatch2 == StudentID then
			local studentID1 = j.StudentMatch1
			local studentID2 = j.StudentMatch2
			return { StudentLevel1 = StudentAccount[studentID1].Level, StudentLevel2 = StudentAccount[studentID2].Level }
		end
	end
	return false
end

function UpdateStudentLevel(StudentID, NewStudentLevel) 
	StudentAccount[StudentID].Level = NewStudentLevel
end
