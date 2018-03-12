Queue = Object:extend()

function Queue:new()
	self.items = {}
	self.length = 0
end


function Queue:Length()
	return self.length
end


function Queue:enqueue(item)
	table.insert(self.items, item)		-- Adds value at end of list
	self.length = self.length + 1
	return true
end


function Queue:dequeue()
	if self:isEmpty() then return 0 end
	local head = table.remove(self.items, 1)			-- First value removed
	self.length = self.length - 1
	return head
end


function Queue:peek()
	if self:isEmpty() then return end
	return self.items[1]
end


function Queue:isEmpty()
	if self.length == 0 then 
		return true
	else
		return false
	end
end

-- Queue:isFull() function unnecessary as tables in Lua are dynamic