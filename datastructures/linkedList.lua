-- File for defining a linked list. Each node has a data value and a 'next' value. The next value points to another linked list. This allows recursion to be used.
-- Methods in lowerCamelCase are called only by the object itself. Methods in PascalCase are called by exterior functions.
Object = require "classic"
LinkedList = Object:extend()

function LinkedList:new(data)
	if data then 
		self.data = data
		self.next = LinkedList()
	end
end

function LinkedList:Length()				-- Uses recursion to calculate the list's length
	if not self.data then 
		return 0
	else
		return self.next:Length() + 1
	end
end

function LinkedList:PeakNode(index)				-- Returns a node's data without removing it from the list
	index = index or self:Length() + 1			-- If no index is provided, view node at the end of the list
	if index > self:Length() + 1 or index < 1 or index % 1 ~= 0 then return false end
end

function LinkedList:viewNode(index)
	if index == 1 then
		return self.data 
	else
		return self.next:viewNode(index - 1)
	end
end

function LinkedList:NewNode(data, index)		-- Some verification before calling the addNode() function (as there is no need to verify the input each time addNode() is called)
	index = index or self:Length() + 1			-- If no index is provided, add node at the end of the list
	if index > self:Length() + 1 or index < 1 or index % 1 ~= 0 then return false end
	return self:addNode(data, index)
end

function LinkedList:addNode(data, index)		-- Uses recursion to add the node
	if index == 1 then							-- Different if head item must be changed, since we don't want to have to return a new linkedList
		local nextData = self.data
		local nextNext = self.next
		self.data = data
		self.next = LinkedList()
		self.next.data = nextData
		self.next.next = nextNext
		return true
	else										-- For every non-head item in the list
		return self.next:addNode(data, index - 1)
	end
end

function LinkedList:PopNode(index)				-- Makes some preliminary checks before removing the node
	index = index or self:Length()									-- Remove last node if no index given
	if index > self:Length() or index < 1 or index % 1 ~= 0 then return false end 	-- Index is further than end of list or before the start
	return self:removeNode(index)
end

function LinkedList:removeNode(index)				-- Uses recursion to remove the node at a specified index
	if index == 1 then
		local thisData = self.data
		self.data = self.next.data
		self.next = self.next.next
		return thisData
	else
		return self.next:removeNode(index - 1)
	end
end

function LinkedList:IsEmpty()				-- True if the linked list is empty. It is then the leaf node
	if not self.data then 
		return true
	else 
		return false
	end
end


-- DEBUG:
function LinkedList:Print()
	print(self.data)
	print()
	if self.next then self.next:Print() end
end