-- This data structure is an adjacency list representing a graph. A list stores the name of each node (integers in this case). Each node 
-- Each node has a linked list containing the nodes to which it is is joined.

Graph = Object:extend()

function Graph:new()
	self.nodes = {}
end


function Graph:NodeNumber()									-- Returns total number of nodes in a graph
	return #self.nodes
end


function Graph:AdjacentNodes(node)							-- Returns number of nodes adjacent to argument node
	return self.nodes[node]:Length()
end


function Graph:EdgesPerNode()								-- Returns the number of edges per node. False if not all nodes have same number.
	local length = -1
	for node,list in pairs(self.nodes) do
		local l = list:Length()
		if length == -1 then
			length = l
		elseif length ~= l then
			return false
		end
	end
	return length
end


function Graph:NewNode(newNode)
	self.nodes[newNode] = LinkedList()					 	-- Set the index given as an argument equal to a new linked list.
end


function Graph:NewEdge(node, connectedNode, value)
	self.nodes[node]:NewNode({ connectedNode, value })		-- Add a value to the linked list representing the node. This is an edge.
end


function Graph:TotalWeight(node)							-- Calculates the sum of the weights of the edges leaving a node 
	if not self.nodes[node] then return false end
	return self.nodes[node]:ScoreTotal()
end


function Graph:TotalNeighbourWeight(node)					-- Calculates sum of the TotalWeight for every neighbour (connected node)
	local neighbourWeight = 0
	local max = 0
	local min = 100000
	local nodeQueue = self.nodes[node]:IDQueue()
	local rounds = nodeQueue:Length()

	while not nodeQueue:isEmpty() do
		local nextNode = nodeQueue:dequeue()
		local currentWeight = self:TotalWeight(nextNode)	-- Stores the TotalWeight of the next node in the queue
		neighbourWeight = neighbourWeight + currentWeight	-- Adds edge sum of this node to the total

		if currentWeight > max then max = currentWeight end
		if currentWeight < min then min = currentWeight end  					 
	end
	if rounds < 3 then max = 0 min = 0 end 					-- Use Median-Buchholtz only if at least three rounds have been completed

	return neighbourWeight - max - min						-- Median-Buchholtz: subtract strongest and weakest opponents
end


function Graph:NodeEdges(node)								-- Returns the number of edges of a node
	return self.nodes[node]:Length()
end


function Graph:AreConnected(node1, node2)					-- Checks if node1 and node2 are connected
	return (self.nodes[node1]:Contains(node2) or self.nodes[node2]:Contains(node1))
end


-- DEBUG:
function Graph:Print()
	for i,j in pairs(self.nodes) do
		print(i.." is connected to nodes: ")
		j:Print()
		print("  Total Score: "..self:TotalWeight(i))
		print("  Opponent Score: "..self:TotalNeighbourWeight(i))
		print()
	end

end