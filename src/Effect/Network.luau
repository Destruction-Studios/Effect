local RunService = game:GetService("RunService")

local FOLDER_NAME = "_remotes"
local REMOTES = {
	RUN = "RunEffect",
	RUN_PRIMARY = "RunEffectPrimary",
	EFFECT_DESTROY = "EffectDestroyed",
	REPLY = "Reply",
}
local Network = {
	REMOTES = REMOTES,
}
Network.__index = Network

function Network.new(parent)
	local self = setmetatable({}, Network)

	self._parent = parent

	return self
end

function Network:InitRemotes()
	if RunService:IsServer() then
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = self._parent
		self._parent = folder
		for _, remoteName in REMOTES do
			local remote = Instance.new("RemoteEvent")
			remote.Name = remoteName
			remote.Parent = self._parent
			self[remoteName] = remote
		end
	else
		self._parent = self._parent:WaitForChild(FOLDER_NAME)
		for _, remoteName in REMOTES do
			local remote = self._parent:WaitForChild(remoteName, 10)
			self[remoteName] = remote
		end
	end
end

function Network:GetRemote(name): RemoteEvent
	return self[name]
end

return Network
