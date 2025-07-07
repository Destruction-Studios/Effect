local Players = game:GetService("Players")

local Signal = require(script.Parent.Parent.Signal)
local Trove = require(script.Parent.Parent.Trove)
local Network = require(script.Parent.Network).new(script.Parent)
local Reply = require(script.Reply)

assert(game:GetService("RunService"):IsServer(), `Can not be run on client`)

local CONN_DISCONNECT_ERR = "Connection is already disconnected"

local currentId = 0

local EffectServer = {}
local EffectClass = {}
EffectClass.__index = EffectClass

function EffectServer.run(name: string, ...: any)
	local effect = EffectServer.new(name)
	effect:Run(...)
	effect:Destroy()
end

function EffectServer.new(name: string)
	local self = setmetatable({}, EffectClass)

	currentId += 1

	self._trove = Trove.new()
	self.Name = name
	self._runArgs = {}
	self._onRun = Signal.new()
	self._onReply = Signal.new()
	self._id = currentId
	self._firedTo = {}
	self._replyConnection = nil

	self._trove:Add(self._onReply)
	self._trove:Add(self._onRun)
	self._trove:Add(function()
		if self._replyConnection then
			self._replyConnection:Disconnect()
		end
	end)

	return self
end

function EffectClass:GetId(): string
	return self._id
end

function EffectClass:Run(...: any)
	self._onRun:Fire(...)

	local remote = Network:GetRemote(Network.REMOTES.RUN)
	local players = self._runArgs.Only or Players:GetPlayers()
	local primary = self._runArgs.Primary

	if primary then
		self._firedTo[primary] = true
		Network:GetRemote(Network.REMOTES.RUN_PRIMARY):FireClient(primary, self.Name, self:GetId(), ...)
	end
	for _, player in players do
		if player == primary then
			continue
		end
		self._firedTo[player] = true
		remote:FireClient(player, self.Name, self:GetId(), ...)
	end

	table.clear(self._runArgs)
end

function EffectClass:OnRun(func: (...any) -> nil)
	local connection = nil

	connection = self._onRun:Connect(func)

	return function()
		assert(connection, CONN_DISCONNECT_ERR)
		connection:Disconnect()
		connection = nil
	end
end

function EffectClass:WithPrimary(primary: Player)
	self._runArgs.Primary = primary

	return self
end

function EffectClass:WithOnly(playerOrPlayers: Player | { Player })
	if typeof(playerOrPlayers) ~= "table" then
		playerOrPlayers = { playerOrPlayers }
	end

	self._runArgs.Only = playerOrPlayers

	return self
end

function EffectClass:OnReply(func: (player: Player, ...any) -> nil)
	if self._replyConnection == nil then
		local con = Network:GetRemote(Network.REMOTES.REPLY).OnServerEvent:Connect(function(player, name, id, ...)
			if not self._firedTo[player] then
				return
			end
			if name ~= self.Name or id ~= self:GetId() then
				return
			end
			self._onReply:Fire(player, ...)
		end)
		self._replyConnection = con
	end

	local reply = Reply.new(self._onReply, func)
	self._trove:Add(reply)

	return reply
end

function EffectClass:Destroy()
	Network:GetRemote(Network.REMOTES.EFFECT_DESTROY):FireAllClients(self.Name, self:GetId())
	self._trove:Clean()
	setmetatable(self, nil)
	table.clear(self)
end

Network:InitRemotes()

--To prevent no OnServerEvent impl error
Network:GetRemote(Network.REMOTES.REPLY).OnServerEvent:Connect(function() end)

return EffectServer
