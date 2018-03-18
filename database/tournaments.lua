-- The following functions could be in table.lua. They are a mixture of algorithmic and database functions used in creating tournament pairings,
-- fetching matches, completing matches, and finding tournament winners (for example). Within this file, in comments, the terms scoreboard
-- and student will be used interchangeably, since a scoreboard represents a student's registration within a tournament, and this file is not
-- concerned with the registrations of students in completed tournaments (in the past).

function CheckTournamentRoundsFinished(dateTime)			-- Checks every running tournament
	for i,t in ipairs(Tournament) do
		CheckRoundFinished(t.TournamentID, dateTime)
	end
end

function DeletePreviousTournament(ClassID)					-- When creating a new tournament, the previous tounament for that class is deleted
	for i,t in ipairs(Tournament) do
		if t.ClassID == ClassID then
			Tournament[i] = nil
			return true
		end
	end
	return false
end

function CheckRoundFinished(TournamentID, dateTime)				-- Checks whether the current round of a tournament is finished
	local t
	for i,j in ipairs(Tournament) do
		if j.TournamentID == TournamentID then
			t = j
		end
	end
	print("TournamentID: "..t.TournamentID)

	if not t.FinalRanking then 		-- Tournament needs updating if it is incomplete but the previous round has timed out
		local nextRoundComplete = NextRound(t.TournamentID)
		if not nextRoundComplete and dateTime.yday >= t.LastRound + t.RoundLength then 		-- Create next round if previous round has timed out
			--Complete the current match (complete any unfinished match)
			nextRoundComplete = NextRound(t.TournamentID)
		end

		if nextRoundComplete then t.LastRound = dateTime.yday end 	-- Update last round start date if a new round has now started
	end
end

function EnrollStudents(ClassID, TournamentID)		-- Upon creation of a tournament, creates a scoreboard for every student in the class
	local studentNo = 0
	for i,student in ipairs(StudentAccount) do
		if student.ClassID == ClassID then
			addScoreboard(TournamentID, student.StudentID)
			studentNo = studentNo + 1
		end
	end
	if studentNo % 2 == 1 then addScoreboard(TournamentID, -1) end 		-- Dummy player added if odd number of players
end

function FindCurrentScoreboardID(StudentID) -- Finds the latest scoreboard of a student. This correponds to a student's registration in a tournament; only the scoreboard for the tournament currently running will be returned.
	local classID = StudentAccount[StudentID].ClassID
	local tournamentID = 0
	for i,t in ipairs(Tournament) do
		if t.ClassID == classID then
			tournamentID = t.TournamentID
		end
	end
	if not tournamentID then return false end
	for i,sc in ipairs(Scoreboard) do
		if sc.StudentID == StudentID and sc.TournamentID == tournamentID then
			return sc.ScoreboardID
		end
	end
end

function NextRound(TournamentID) 							-- Overall, creates the next set of matches in a tournament (every pairing for the next round). Every player in the tournament will play in every round
	local graph = CreateTournamentGraph(TournamentID)
	if not graph then print("No graph created"); return false end							-- Return if the current round is unfinished
	local rounds = graph:EdgesPerNode()
	local playerCount = graph:NodeNumber()
	local finalRound = math.ceil(math.log(playerCount, 2))
	graph:Print()

	local rankedStudents = TournamentRanking(graph)
	local nextPairing = {}

	if rounds == 0 then
		print("Tournament Starting")
		nextPairing = FirstRoundMatches(rankedStudents)
	elseif rounds == finalRound then
		print("Tournament Finished")
		FinishTournament(TournamentID, rankedStudents, graph)
	else
		print("Tournament Ongoing")
		print("Rounds complete: "..rounds)
		nextPairing = TournamentPairing(rankedStudents, graph)
	end

	AddPairings(nextPairing)
	NotifyStudentsOfNewMatch(TournamentID, nextPairing)

	for i,j in pairs(nextPairing) do						-- Automatically complete the match of the dummy player and its opponent
		if ScoreboardStudent(j) == -1 then CompleteMatch(i, j, 500, 0) end
	end

	return true
end


function FirstRoundMatches(rankedStudents) 		-- Create a random pairing of students for the first round (before any data is available for pairing students)
	local nextPairing = {}
	for i = 1, #rankedStudents do
		local student1 = rankedStudents[i].ID
		if not nextPairing[student1] then  		-- If the student is not already paired, find a random pairing for them.
			local rand = love.math.random(i + 1, #rankedStudents)
			while nextPairing[rankedStudents[rand].ID] do 		-- Find a new match if the other student is already paired
				rand = love.math.random(i + 1, #rankedStudents)
			end
			nextPairing[student1] = rankedStudents[rand].ID
			nextPairing[rankedStudents[rand].ID] = student1
		end
	end
	return nextPairing
end


function CreateTournamentGraph(TournamentID)	-- Creates a graph to represent the current state of the tournament.
	local tournamentG = Graph()
	local students = {}
	-- Retrieve the Scoreboards of every student in the tournament.
	-- Add every Scoreboard as a node to the graph:
	for i,s in ipairs(Scoreboard) do
		if s.TournamentID == TournamentID then
			tournamentG:NewNode(s.ScoreboardID)
			students[s.ScoreboardID] = 0
		end
	end

	-- Retrieve every StudentMatch in the tournament.
	-- Add every StudentMatch as an edge to the graph:
	for i,s in ipairs(StudentMatch) do
		if students[s.FromScoreboardID] then	-- If FromScoreboardID is in the tournament, then so is ToScoreboardID.
			if not s.PointsWon then return false end	-- If PointsWon is nil, the current round is unfinished
			tournamentG:NewEdge(s.FromScoreboardID, s.ToScoreboardID, s.PointsWon)		-- Add tournament match as an edge
		end
	end

	return tournamentG or Graph()
end


function GraphToScoreboard(graph)  		-- Convert a graph into a table where every index represents a student scoreboard ID, pointing to the student's total score in the tournament thus far.
	local l = {}
	for i,j in pairs(graph.nodes) do
		l[i] = graph:TotalWeight(i)
	end
	return l
end


function GraphToList(graph) 			-- Convert a graph to a list of tables. Each subtable contains the ID and total score of the student in this tournament. This form allows for easy sorting of the list.
	local l = {}
	for i,j in pairs(graph.nodes) do
		table.insert(l, { score = graph:TotalWeight(i), ID = i })
	end
	return l
end


function TournamentRanking(graph)					-- Finds a pairing for every student for the next round of the tournament
	local rankedStudents = {}						-- Every scoreboardID and total score, in a form for easy sorting

	-- Get a ranking for the students:
	rankedStudents = GraphToList(graph)
	rankedStudents = mergeSort(rankedStudents, graph)		-- Sorts the students in order of decreasing score (resolving ties)

	return rankedStudents
end


function TournamentPairing(rankedStudents, graph)	-- Gets the next pairing in the tournament
	local nextPairing = {}							-- Stores a table for each pair
	local unpaired = {}								-- List of students with no valid pairings (max 2)
	for i = 1,#rankedStudents do 			-- The actual pairing. Not O(n^2) because worst case is 5 failed pairings, not the entire list.
		for j = i + 1,#rankedStudents do
			print("Index: "..i.." "..j)
			local student1 = rankedStudents[i].ID
			local student2 = rankedStudents[j].ID
			if nextPairing[student1] then break end
			if not graph:AreConnected(student1, student2) and not nextPairing[student2] then
			-- ^ Only pair these students if they haven't been paired before and neither is currently paired
				nextPairing[student1] = student2
				nextPairing[student2] = student1
				break
			end
		end
	end

	for i,j in pairs(nextPairing) do
		print(i.." paired with "..j)
	end

	return nextPairing
end


function mergeSort(list, graph)						-- Takes a table in the format { score = _, ID = _ } and a graph and sorts the items in order of decreasing score
	local midpoint = math.ceil(#list / 2)			-- The graph is passed by reference, so there is no issue with efficiency.
	local first = { unpack(list, 1, midpoint) }
	local second = { unpack(list, midpoint + 1) }
	local sorted = {}

	if #first > 1 then
		first = mergeSort(first, graph)
	end
	if #second > 1 then
		second = mergeSort(second, graph)
	end

	for i = 1, (#first + #second) do
		if #second == 0 or (first[1] or { score = 0 }).score > second[1].score then
		-- ^ Checks if second table is empty or has a smaller head value. Lazy evaluation means	no errors if second table is empty.
		-- ^ { score = 0 } to avoid any errors if the first list is empty
			table.insert(sorted, first[1])
			table.remove(first, 1)
		elseif #first == 0 or (second[1]).score > first[1].score or graph:TotalWeight(second[1].ID) > graph:TotalWeight(first[1].ID) then
		-- ^ Checks if first table is empy or has a smaller head value. Second table is never empty here (tested in first statement above)
		-- ^ Also uses the Median Buchholtz System (total sum of opponents except greatest and least) to resolve any ties
			table.insert(sorted, second[1])
			table.remove(second, 1)
		else
		-- Here, neither table is empty and the head items have equal scores, but the opponent score sum is greater for the first table head
			table.insert(sorted, first[1])
			table.remove(first, 1)
		end
	end

	return sorted
end


function AddPairings(nextPairing) 		-- Once every pair for the next round has been chosen, add these to the StudentMatch table with a nil score
	local seed = CreateMatchSeed()		-- One seed for the entire tournament, since each player will only use it once
	for i,j in pairs(nextPairing) do
		addStudentMatch(i, j, seed)
	end
end


function GetIncompleteMatchAgainst(ScoreboardID)	-- A student has completed the latest match in the current tournament. Return the match against them (their opponent's score on the same match) in order to combine the two scores into complete matches.
	for i,m in ipairs(IncompleteMatch) do
		if m.ToScoreboardID == ScoreboardID then
			return m
		end
	end
	return false
end


function CheckOpponentMatchComplete(ScoreboardID)	-- Checks whether a student registered in a tournament has yet to complete the match in the current round
	for i,j in ipairs(StudentMatch) do
		if j.TpScoreboardID == ScoreboardID and StudentMatch.PointsWon then
			return true
		end
	end
	for i,j in ipairs(IncompleteMatch) do
		if j.ToScoreboardID == ScoreboardID then
			return true
		end
	end
	return false
end


function CompleteMatch(FromScoreboardID, ToScoreboardID, Score1, Score2) 	-- Once both students have finished their match (against each other), add this as a complete match to the StudentMatch table
	local player1Points = 0
	if Score1 > Score2 then
		player1Points = 3
	else
		player1Points = 0
	end
	for i,match in ipairs(StudentMatch) do
		if match.FromScoreboardID == FromScoreboardID and match.ToScoreboardID == ToScoreboardID then
			match.PointsWon = player1Points
		elseif match.FromScoreboardID == ToScoreboardID and match.ToScoreboardID == FromScoreboardID then
			match.PointsWon = 3 - player1Points
		end
	end
	-- Remove any incomplete matches:
	for i,j in ipairs(IncompleteMatch) do
		if (j.FromScoreboardID == FromScoreboardID and j.ToScoreboardID == j.ToScoreboardID) or (j.FromScoreboardID == ToScoreboardID and j.ToScoreboardID == FromScoreboardID) then
			table.remove(IncompleteMatch, i)
		end
	end
end


function FindCurrentMatch(ScoreboardID) 	-- Returns a student's next match, and false if there is none available
	for i,match in ipairs(IncompleteMatch) do  		-- Check if the student has already completed the match (but not their opponent)
		if match.FromScoreboardID == ScoreboardID then
			return false
		end
	end

	for i,match in ipairs(StudentMatch) do			-- Check if both players have finished the match
		if match.FromScoreboardID == ScoreboardID and not match.PointsWon then
			return match
		end
	end

	return false
end

function ReturnScoreboardStudent(ScoreboardID)		-- Returns the student given the ID of one of their scoreboards
	for i,j in ipairs(Scoreboard) do
		if j.ScoreboardID == ScoreboardID and j.StudentID ~= -1 then
			return StudentAccount[j.StudentID]
		end
	end
	return false
end

function ReturnScoreboardTournament(ScoreboardID)	-- Return the record for the tournament to which a scoreboard belongs
	local TournamentID
	for i,sc in ipairs(Scoreboard) do
		if sc.ScoreboardID == ScoreboardID then
			TournamentID = sc.TournamentID
		end
	end
	if not TournamentID then return false end
	for i,t in ipairs(Tournament) do
		if t.TournamentID == TournamentID then
			return t
		end
	end
	return false
end

function FindTournamentRoundTime(TournamentID) 	-- Return the time each tounament round lasts, given the tournament ID
	for i,t in ipairs(Tournament) do
		if t.TournamentID == TournamentID then
			return t.RoundLength
		end
	end
end

function CreateMatchSeed()	-- Creates the reference of the seed from which match questions will be generated. This is thick-client computing: minimum effort is given by the server while still ensuring the two students get the same questions in the match
	local seed = love.math.random(1, 10000000)
	return seed
end

function IsStudentInMatch(StudentID)	-- Checks if a student currently has a match to complete
	print("Student: "..StudentID)
	local classID
	local class
	local scoreboard
	local match

	classID = FindStudentClass(StudentID)
	if not classID then return false end

	for i,c in ipairs(Class) do
		if c.ClassID == classID then
			class = c
		end
	end

	for i,sc in ipairs(Scoreboard) do
		if sc.StudentID == StudentID then
			scoreboard = sc
		end
	end
	if not scoreboard then return false end

	for i,m in ipairs(StudentMatch) do
		if m.FromScoreboardID == scoreboard.ScoreboardID and not m.PointsWon then
			match = m
		end
	end
	if not match then return false end

	local opponent = ReturnScoreboardStudent(match.ToScoreboardID)
	if not opponent then return false end 					-- Check that opponent isn't the bye student

	for i,im in ipairs(IncompleteMatch) do
		if im.FromScoreboardID == scoreboard.ScoreboardID then
			return false
		end
	end
	return true
end

function ScoreboardStudent(ScoreboardID) 		-- Returns the ID of the student who owns a scoreboard (given the ScoreboardID)
	for i,sc in ipairs(Scoreboard) do
		if sc.ScoreboardID == ScoreboardID then
			return sc.StudentID
		end
	end
	return false
end

function ReturnTournamentClass(TournamentID)	-- Returns the record for the class registered in a tournament
	local classID
	for i,t in ipairs(Tournament) do
		if t.TournamentID == TournamentID then
			classID = t.ClassID
		end
	end
	for i,class in ipairs(Class) do
		if class.ClassID == classID then
			return class
		end
	end
	return false
end

function ConvertScoreboardToStudent(scoreboardRanks)				-- Takes a table of tables of the form { ID = _, score = _ } and converts every ScoreboardID to the StudentID of the appropriate student
	local studentRanks = {}
	for i,j in ipairs(scoreboardRanks) do
		local student = ReturnScoreboardStudent(j.ID)
		if student then table.insert(studentRanks, { ID = student.StudentID, score = j.score }) end
	end
	return studentRanks
end

function FinishTournament(TournamentID, rankedStudents, graph)	-- Called at the end of a tournament. Deletes records involved and send final tournament information to teacher and students
	-- Send student ranking to teacher:
	local class = ReturnTournamentClass(TournamentID)
	rankedStudents = ConvertScoreboardToStudent(rankedStudents)
	local ranking = table.serialize(rankedStudents)
	print(ranking)
	SendTeacherTournamentEnd(class.TeacherID, class.ClassName, ranking)

	-- Send winner and ranking to every student:




	-- Delete every match in the tournament:
	for i,m in ipairs(StudentMatch) do
		if graph:NodeExists(m.FromScoreboardID) then		-- Check if scoreboard is part of this tournament
			StudentMatch[i] = nil
		end
	end

	-- Delete every scoreboard in the tournament:
	for i,sc in ipairs(Scoreboard) do						-- Check if this scoreboard is in the tournament
		if graph:NodeExists(sc.ScoreboardID) then
			Scoreboard[i] = nil
		end
	end
end



function printList(list) for i,j in pairs(list) do print("ID: "..j.ID) print("Score: "..j.score) print() end end
