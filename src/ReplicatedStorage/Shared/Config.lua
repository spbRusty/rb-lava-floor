local Config = {}

Config.MIN_PLAYERS = 2 -- Use 1 temporarily for solo Studio testing.
Config.INTERMISSION_SECONDS = 15
Config.ROUND_SECONDS = 100
Config.LAVA_START_Y = -12
Config.LAVA_RISE_INTERVAL = 3
Config.LAVA_RISE_AMOUNT = 2
Config.WIN_REWARD = 50
Config.PARTICIPATION_REWARD = 10
Config.ARENA_CENTER = Vector3.new(0, 0, 300)
Config.LOBBY_SPAWN = Vector3.new(0, 8, 0)

return Config