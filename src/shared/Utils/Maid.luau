-- Maid.luau
-- Minimal cleanup helper. Accepts connections, instances, functions, or objects with :Destroy().

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Give(item)
	table.insert(self._tasks, item)
	return item
end

function Maid:Clean()
	local tasks = self._tasks
	self._tasks = {}
	for _, item in ipairs(tasks) do
		if typeof(item) == "RBXScriptConnection" then
			item:Disconnect()
		elseif typeof(item) == "Instance" then
			item:Destroy()
		elseif typeof(item) == "function" then
			item()
		elseif type(item) == "table" and typeof(item.Destroy) == "function" then
			item:Destroy()
		end
	end
end

Maid.Destroy = Maid.Clean

return Maid
