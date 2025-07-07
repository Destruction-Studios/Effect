local RunService = game:GetService("RunService")

export type Context = {
	GetName: (self: Context) -> string,
	Reply: (self: Context, ...any) -> nil,
}

export type Reply = {
	TimesFired: (self: Reply) -> number,

	LimitedTo: (self: Reply, amount: number) -> Reply,
	Once: (self: Reply) -> Reply,
	RateLimitedTo: (self: Reply, seconds: number) -> Reply,
	OnlyFrom: (self: Reply, playerOrPlayers: { Player } | Player) -> Reply,
	Disconnect: (self: Reply) -> nil,
	Destroy: (self: Reply) -> nil,
}

export type EffectClass = {
	GetId: (self: EffectClass) -> any,

	Start: (self: EffectClass) -> nil,
	Run: (self: EffectClass, context: Context, ...any) -> EffectClass,
	RunPrimary: (self: EffectClass, context: Context, ...any) -> EffectClass,

	OnRun: (self: EffectClass, func: (...any) -> nil) -> () -> nil,
	OnReply: (self: EffectClass, func: (player: Player, ...any) -> nil) -> Reply,
	WithPrimary: (self: EffectClass, primary: Player) -> EffectClass,
	WithOnly: (self: EffectClass, playerOrPlayers: { Player } | Player) -> EffectClass,

	Destroy: (self: EffectClass) -> nil,
}

export type Effect = {
	new: (effectName: string) -> EffectClass,
	run: (effectName: string) -> nil,
	start: () -> nil,
}

if RunService:IsServer() then
	return require(script.Server) :: Effect
else
	return require(script.Client) :: Effect
end
