local Reply = {}
Reply.__index = Reply

function Reply.new(signal, func)
	local self = setmetatable({}, Reply)

	self._lastFired = 0
	self._timesFired = 0
	self.Connection = signal:Connect(function(player, ...)
		if self._only and table.find(self._only, player) ~= nil then
			return
		end
		if self._rateLimit then
			if tick() - self._lastFired < self._rateLimit then
				return
			end
			self._lastFired = tick()
		end
		if self._fireLimit and self._timesFired >= self._fireLimit then
			return
		end
		self._timesFired += 1

		func(player, ...)
	end)

	return self
end

function Reply:LimtedTo(limit)
	self._fireLimit = limit
	return self
end

function Reply:Once()
	return self:LimtedTo(1)
end

function Reply:RateLimitedTo(seconds)
	self._rateLimit = seconds
	return self
end

function Reply:OnlyFrom(playerOrPlayers: Player | { Player })
	if typeof(playerOrPlayers) ~= "table" then
		playerOrPlayers = { playerOrPlayers }
	end

	self._only = playerOrPlayers
	return self
end

function Reply:Destroy()
	if self.Connection and self.Connection.Connected then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

return Reply
