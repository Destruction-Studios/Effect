local Context = {}
local ContextMT = {}
ContextMT.__index = ContextMT

function Context.new(name, id, replyEvent)
	local self = setmetatable({}, ContextMT)

	self._name = name
	self._id = id
	self._replyEvent = replyEvent

	return self
end

function ContextMT:GetName(): string
	return self._name
end

function ContextMT:GetId(): number
	return self._id
end

function ContextMT:Reply(...)
	self._replyEvent:FireServer(self:GetName(), self:GetId(), ...)
end

return Context
