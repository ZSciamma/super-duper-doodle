-- This data structure is an adjacency list representing a graph. A list stores the name of each node (integers in this case). Each node 
-- Each node has a linked list containing the nodes to which it is is joined.

Graph = Object:extend()

function Graph:new()
	self.nodes = {}
end

function Graph:NewNode(newNode)
	self.nodes[newNode] = LinkedList()					 	-- Set the index given as an argument equal to a new linked list.
end

function Graph:NewEdge(node, connectedNode, value)
	self.nodes[node]:NewNode({ connectedNode, value })		-- Add a value to the linked list representing the node. This is an edge.
end

function Graph:Print()
	for i,j in pairs(self.nodes) do
		print(i.." is connected to nodes: ")
		j:Print()
		print()
	end
end