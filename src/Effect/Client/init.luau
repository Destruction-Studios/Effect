export type EffectParams = {
	Name: string,
}

local started = false
local effectClasses = {}

assert(game:GetService("RunService"):IsClient(), `Can not be run on server`)

local Network = require(script.Parent.Network).new(script.Parent)
local Context = require(script.Context)

export type ContextType = typeof(Context.new())

local EffectClient = {}
local EffectClientMT = {}
EffectClientMT.__index = EffectClientMT

local EffectObject = {}
EffectObject.__index = EffectObject

local function getOrCreateEffect(name, id)
	local class = effectClasses[name]
	if class._objects[id] ~= nil then
		return class._objects[id]
	end
	class._objects[id] = {
		Id = id,
		Name = name,
	}
	return class._objects[id]
end

function EffectClient.new(params: EffectParams)
	assert(not effectClasses[params.Name], `Effect {params.Name} already exists`)
	local self = setmetatable({}, EffectClientMT)

	self.Name = params.Name
	self._objects = {}

	effectClasses[params.Name] = self

	return self
end

--selene:allow(unused_variable)
function EffectClientMT.Run(self, context: ContextType, ...) end

--selene:allow(unused_variable)
function EffectClientMT.RunPrimary(self, context: ContextType, ...) end

--selene:allow(unused_variable)
function EffectClientMT.Destroy(self) end

Network:InitRemotes()

function EffectClient:Start()
	assert(not started, `Effect has already been started`)
	started = true

	for _, remoteName in Network.REMOTES do
		Network:GetRemote(remoteName).OnClientEvent:Connect(function(effectName, id, ...)
			local class = effectClasses[effectName]
			if not effectClasses[effectName] then
				error(`No effect class for "{effectName}"`, 2)
				return
			end
			if remoteName == Network.REMOTES.EFFECT_DESTROY then
				local effect = class._objects[id]
				if effect then
					class.Destroy(effect)
				end
			else
				local context = Context.new(effectName, id, Network:GetRemote(Network.REMOTES.REPLY))
				local effect = getOrCreateEffect(effectName, id)
				if remoteName == Network.REMOTES.RUN_PRIMARY then
					class.RunPrimary(effect, context, ...)
				end
				class.Run(effect, context, ...)

				--Clear context after use
				--!!could cause errors if context is used in diff thread!!
				-- setmetatable(context, nil)
				-- table.clear(context)
			end
		end)
	end
end

return EffectClient
