local Config = {}

-- Monetization
Config.VIP_GAME_PASS_ID = 2087837274

-- Audio: set these to uploaded Roblox audio asset IDs (0 = disabled).
Config.MUSIC_ASSET_ID = 0
Config.SOUND_JUMP = 0
Config.SOUND_LAVA = 0
Config.SOUND_TRAP = 0
Config.SOUND_ELIMINATE = 0
Config.SOUND_WIN = 0
Config.SOUND_SHOP = 0
Config.SOUND_ROUND_START = 0

-- Match flow
Config.MIN_PLAYERS = 1
Config.SOLO_BOT_COUNT = 2
Config.PLAYER_JUMP_POWER = 55
Config.INTERMISSION_SECONDS = 15
Config.ROUND_SECONDS = 100
Config.POST_ROUND_SECONDS = 6
Config.WIN_REWARD = 50
Config.PARTICIPATION_REWARD = 10

-- Arena placement
Config.ARENA_CENTER = Vector3.new(0, 0, 300)
Config.LOBBY_SPAWN = Vector3.new(0, 8, 0)
Config.LAVA_START_Y = -12
Config.LAVA_RISE_INTERVAL = 3
Config.LAVA_RISE_AMOUNT = 2

-- Max edge-to-edge gap used by route validation and bot option filtering.
Config.MAX_EDGE_GAP = 7.5

-- Bot tuning (on top of validated edge jumps)
Config.BOT_JUMP_POWER = 55
Config.BOT_WALK_SPEED = 16
Config.BOT_STUCK_TIMEOUT = 6.5
Config.BOT_SOFT_RECOVERY_ATTEMPTS = 2
Config.BOT_TELEPORT_AFTER = 3
Config.BOT_ESCALATE_AFTER = 5
Config.BOT_RECOVERY_TELEPORT_Y = 3.2
Config.BOT_THINK_MIN = 0.1
Config.BOT_THINK_MAX = 0.28
Config.BOT_TARGET_RANDOMNESS = 0.35

-- Shop (buffs apply to the next round)
Config.SHOP = {
	JumpBoost = {
		Id = "JumpBoost",
		Name = "Jump Boost",
		Description = "+12 JumpPower next round",
		Price = 40,
		DurationRounds = 1,
	},
	SpeedBoost = {
		Id = "SpeedBoost",
		Name = "Speed Boost",
		Description = "+4 WalkSpeed next round",
		Price = 30,
		DurationRounds = 1,
	},
	SecondChance = {
		Id = "SecondChance",
		Name = "Second Chance",
		Description = "One free revive if you fall in lava next round",
		Price = 80,
		DurationRounds = 1,
	},
}

-- Round modifiers
Config.MODIFIERS = {
	{
		Id = "Standard",
		Name = "STANDARD",
		Description = "Classic rising lava",
		Weight = 28,
		LavaIntervalMul = 1,
		LavaAmountMul = 1,
		HazardCount = 2,
		PlatformScale = 1,
		LayerBonus = 0,
		JumpPowerBonus = 0,
		FogDensity = nil,
	},
	{
		Id = "FastLava",
		Name = "FAST LAVA",
		Description = "Lava rises faster",
		Weight = 18,
		LavaIntervalMul = 0.65,
		LavaAmountMul = 1.15,
		HazardCount = 2,
		PlatformScale = 1,
		LayerBonus = 0,
		JumpPowerBonus = 0,
		FogDensity = nil,
	},
	{
		Id = "HazardHeavy",
		Name = "HAZARD HEAVY",
		Description = "More rotating sweepers",
		Weight = 16,
		LavaIntervalMul = 1,
		LavaAmountMul = 1,
		HazardCount = 4,
		PlatformScale = 1,
		LayerBonus = 0,
		JumpPowerBonus = 0,
		FogDensity = nil,
	},
	{
		Id = "NarrowPaths",
		Name = "NARROW PATHS",
		Description = "Slightly smaller platforms",
		Weight = 14,
		LavaIntervalMul = 1,
		LavaAmountMul = 1,
		HazardCount = 2,
		PlatformScale = 0.88,
		LayerBonus = 0,
		JumpPowerBonus = 0,
		FogDensity = nil,
	},
	{
		Id = "SkyClimb",
		Name = "SKY CLIMB",
		Description = "Extra vertical layers",
		Weight = 12,
		LavaIntervalMul = 1.05,
		LavaAmountMul = 1,
		HazardCount = 3,
		PlatformScale = 0.95,
		LayerBonus = 2,
		JumpPowerBonus = 4,
		FogDensity = nil,
	},
	{
		Id = "AshFog",
		Name = "ASH FOG",
		Description = "Thick volcanic fog",
		Weight = 12,
		LavaIntervalMul = 1,
		LavaAmountMul = 1,
		HazardCount = 2,
		PlatformScale = 1,
		LayerBonus = 0,
		JumpPowerBonus = 0,
		FogDensity = 0.38,
	},
}

Config.COLORS = {
	Background = Color3.fromRGB(13, 17, 28),
	Panel = Color3.fromRGB(24, 31, 47),
	Accent = Color3.fromRGB(255, 112, 54),
	Gold = Color3.fromRGB(255, 204, 92),
	Cyan = Color3.fromRGB(76, 220, 235),
	Green = Color3.fromRGB(89, 225, 154),
}

return Config
