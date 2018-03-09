function PlayerCount(TournamentID)
	local playerCount = 0
	for i,scoreboard in ipairs(Scoreboard) do
		if scoreboard.TournamentID == TournamentID then
			playerCount = playerCount + 1
		end
	end
	return playerCount
end

function TournamentRanking(TournamentID)
	local students = {}
	local ranking = {}
	-- Retrieve the scoreboards of all students in the tournament and their score
	for i,s in ipairs(Scoreboard) do
		if s.TournamentID == TournamentID then
			table.insert(students, { score = s.Score, ID = s.StudentID } )
		end
	end

	students = mergeSort(students)				-- Sorts the students in decreasing order
end

function mergeSort(list)						-- Takes a table in the format { score = _, ID = _ } and sorts the items in order of decreasing score
	local midpoint = math.ceil(#list / 2)
	local first = { unpack(list, 1, midpoint) }
	local second = { unpack(list, midpoint + 1) }
	local sorted = {}

	if #first > 1 then
		first = mergeSort(first)
	end
	if #second > 1 then
		second = mergeSort(second)
	end

	for i = 1, (#first + #second) do
		if #second == 0 or (first[1] or { score = 0 }).score > second[1].score then		-- Checks if second table is empty or has a smaller head value
			table.insert(sorted, first[1])
			table.remove(first, 1)
		else
			table.insert(sorted, second[1])
			table.remove(second, 1)
		end
	end

	return sorted
end

function 