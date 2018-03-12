function EnrollStudents(ClassID, TournamentID)		-- Upon creation of a tournament, creates a scoreboard for every student in the class
	local studentNo = 0
	for i,student in ipairs(StudentAccount) do
		if student.ClassID == ClassID then
			addScoreboard(TournamentID, student.StudentID)
			studentNo = studentNo + 1
		end
	end
	if studentNo % 2 == 1 then addScoreboard(TournamentID, -1) end 		-- Dummy player if odd number of players
end


function NextRound(TournamentID)
	local graph = CreateTournamentGraph(TournamentID)
	local rounds = graph:EdgesPerNode()
	local playerCount = graph:NodeNumber()
	local finalRound = math.ceil(math.log(playerCount, 2))

	local rankedStudents = TournamentRanking(graph)
	local nextPairing = {}

	debug.debug()
	if rounds == 0 then
		nextPairing = FirstRoundMatches(rankedStudents)
	elseif rounds == finalRound then
		FinishTournament(rankedStudents, graph)
	else
		nextPairing = TournamentPairing(rankedStudents, graph)
	end

	AddPairings(nextPairing)

	debug.debug()
end


function FirstRoundMatches(rankedStudents)
	local nextPairing = {}
	for i = 1, #rankedStudents do
		local student1 = rankedStudents[i].ID
		if not nextPairing[student1] then 
			local rand = love.math.random(i + 1, #rankedStudents)
			while nextPairing[rankedStudents[rand].ID] do
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


function GraphToScoreboard(graph) 
	local l = {} 
	for i,j in pairs(graph.nodes) do 
		l[i] = graph:TotalWeight(i) 
	end 
	return l 
end


function GraphToList(graph) 
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


function AddPairings(nextPairing)
	for i,j in pairs(nextPairing) do
		addStudentMatch(i, j)
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



