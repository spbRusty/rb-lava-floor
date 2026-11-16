local Config = {}

-- Match flow
Config.MIN_PLAYERS = 2
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

-- Visual style
Config.COLORS = {
    Background = Color3.fromRGB(13, 17, 28),
    Panel = Color3.fromRGB(24, 31, 47),
    Accent = Color3.fromRGB(255, 112, 54),
    Gold = Color3.fromRGB(255, 204, 92),
    Cyan = Color3.fromRGB(76, 220, 235),
    Green = Color3.fromRGB(89, 225, 154),
}

return Config
