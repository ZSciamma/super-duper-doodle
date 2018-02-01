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
		ClassName = ClassName
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
		Password = Password
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

function addTournament(TeacherID, WinnerID)
	local TournamentNo = #Tournament
	local newTournament = {
		TournamentID = TournamentNo + 1,
		WinnerID = WinnerID,
		TeacherID = TeacherID
	}
	table.insert(Tournament, TournamentNo)
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

function StudentEmailTaken(EmailAddress)
	for i,j in ipairs(StudentAccount) do
		if j.EmailAddress == EmailAddress then return true end
	end
	return false
end

function TeacherEmailTaken(EmailAddress)
	for i,teacher in ipairs(TeacherAccount) do
		if teacher.EmailAddress == EmailAddress then return true end
	end
	return false
end

function ConfirmClassCode(JoinCode)
	for i,class in ipairs(Class) do
		if class.JoinCode == JoinCode then 
			return { className = class.ClassName, TeacherID = class.TeacherID }
		end
	end
	return ""
end

function ValidateStudentID(StudentID, Password)
	local student = StudentAccount[StudentID]
	if StudentID == student.StudentID and Password == student.Password then
		return true
	end
	return false
end

function ValidateTeacherID(TeacherID, Password)
	local teacher = TeacherAccount[TeacherID]
	if TeacherID == teacher.TeacherID and Password == teacher.Password then
		return true
	end
	return false
end