Graph = Object:extend()
Node = Object:extend()

function Graph:new(_data)
	self.node = Node(_data)
end

function Graph:add(_data)
	table.insert(self.node.graphs, Graph(_data))
end

function Node:new(_data)
	self.data = _data
	self.graphs = {}
end

function Node:changeValue(newData)
	self.data = newData
end