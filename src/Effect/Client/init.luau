local started = false
local effectClasses = {}

assert(game:GetService("RunService"):IsClient(), `Can not be run on server`)

local Network = require(script.Parent.Network).new(script.Parent)
local Context = require(script.Context)
local noYield = require(script.Parent.noYield)

local startNoYield = noYield("Attempted to yield in start function")
local contextModiferNoYield = noYield("Attempted to yeild in context modifier")

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
	class._objects[id] = setmetatable({
		_id = id,
		Name = name,
	}, EffectObject)
	startNoYield(class.Start, class._objects[id])
	return class._objects[id]
end

function EffectClient.new(name: string)
	assert(typeof(name) == "string", `Expected string got {typeof(name)}`)
	assert(not effectClasses[name], `Effect {name} already exists`)
	local self = setmetatable({}, EffectClientMT)

	self.Name = name
	self._objects = {}

	effectClasses[name] = self

	return self
end

--selene:allow(unused_variable)
function EffectClientMT.Start(self) end

--selene:allow(unused_variable)
function EffectClientMT.Run(self, context: ContextType, ...) end

--selene:allow(unused_variable)
function EffectClientMT.RunPrimary(self, context: ContextType, ...) end

--selene:allow(unused_variable)
function EffectClientMT.Destroy(self) end

function EffectObject:GetId()
	return self._id
end

Network:InitRemotes()

function EffectClient.start(contextModifier)
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
					setmetatable(effect, nil)
					table.clear(effect)
					class._objects[id] = nil
				end
			else
				local context = Context.new(effectName, id, Network:GetRemote(Network.REMOTES.REPLY))

				if contextModifier then
					contextModiferNoYield(contextModifier, context)
				end

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
