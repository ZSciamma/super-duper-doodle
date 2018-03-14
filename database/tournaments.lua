-- The following functions could be in table.lua. They are a mixture of algorithmic and database functions used in creating tournament pairings,
-- fetching matches, completing matches, and finding tournament winners (for example). Within this file, in comments, the terms scoreboard
-- and student will be used interchangeably, since a scoreboard represents a student's registration within a tournament, and this file is not
-- concerned with the registrations of students in completed tournaments (in the past). 

function CheckTournamentRoundsFinished(dateTime)			-- Checks every running tournament 
	for i,t in ipairs(Tournament) do
		if (not t.WinnerID and dateTime.yday >= t.LastRound + t.RoundLength) then		-- Tournament needs updating if it is incomplete but the previous round has timed out
			NextRound(t.TournamentID)
			t.LastRound = t.yday
		end
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
	for i,class in ipairs(Class) do
		if Class.ClassID == classID then
			tournamentID = Class.TournamentID
		end
	end
	for i,sc in ipairs(Scoreboard) do
		if sc.TournamentID == tournamentID then
			return sc.ScoreboardID
		end
	end
end

function NextRound(TournamentID) 							-- Overall, creates the next set of matches in a tournament (every pairing for the next round). Every player in the tournament will play in every round
	local graph = CreateTournamentGraph(TournamentID)
	local rounds = graph:EdgesPerNode()
	local playerCount = graph:NodeNumber()
	local finalRound = math.ceil(math.log(playerCount, 2))

	local rankedStudents = TournamentRanking(graph)
	local nextPairing = {}

	if rounds == 0 then
		nextPairing = FirstRoundMatches(rankedStudents)
	elseif rounds == finalRound then
		FinishTournament(TournamentID, rankedStudents, graph)
	else
		nextPairing = TournamentPairing(rankedStudents, graph)
	end

	AddPairings(nextPairing)

	debug.debug()
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
	for i,j in pairs(nextPairing) do
		addStudentMatch(i, j)
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


function CheckMatchComplete(ScoreboardID)	-- Checks whether a student registered in a tournament has yet to complete the match in the current round
	for i,j in ipairs(StudentMatch) do
		if j.FromScoreboardID == ScoreboardID and StudentMatch.PointsWon then
			return true
		end
	end
	for i,j in ipairs(IncompleteMatch) do
		if j.FromScoreboardID == ScoreboardID then
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
end


function FindCurrentMatch(ScoreboardID) 	-- Returns a student's next match
	for i,match in ipairs(StudentMatch) do
		if match.FromScoreboardID == match.ToScoreboardID then
			return match
		end
	end
end

--[[
function RoundNumber(TournamentID)				-- Finds the number of rounds compeleted in a tournament by looking at every match of a specific student
	local inspected = 0
	for i,scoreboard in ipairs(Scoreboard) do
		if scoreboard.TournamentID == TournamentID then
			inspected = scoreboard.ScoreboardID
		end
	end

	local rounds = 0
	for i,match in ipairs(StudentMatch) do
		if match.FromScoreboardID == inspected then
			rounds = rounds + 1
		end
	end

	return rounds
end
--]]


--[[
function PlayerCount(TournamentID)
	local playerCount = 0
	for i,scoreboard in ipairs(Scoreboard) do
		if scoreboard.TournamentID == TournamentID then
			playerCount = playerCount + 1
		end
	end
	return playerCount
end
--]]



