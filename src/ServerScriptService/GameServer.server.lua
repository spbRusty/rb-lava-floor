local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local statsStore = DataStoreService:GetDataStore("FloorIsLava_PlayerStats_v1")

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local roundState = remotes:FindFirstChild("RoundState") or Instance.new("RemoteEvent")
roundState.Name = "RoundState"
roundState.Parent = remotes

local world = workspace:FindFirstChild("FloorIsLavaWorld") or Instance.new("Folder")
world.Name = "FloorIsLavaWorld"
world.Parent = workspace

local lobby = world:FindFirstChild("Lobby") or Instance.new("Folder")
lobby.Name = "Lobby"
lobby.Parent = world

local arenaFolder = world:FindFirstChild("Arena") or Instance.new("Folder")
arenaFolder.Name = "Arena"
arenaFolder.Parent = world

local alive = {}
local roundActive = false

local function makePart(parent, name, size, position, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Parent = parent
    return part
end

local function buildLobby()
    if lobby:FindFirstChild("LobbyFloor") then
        return
    end

    makePart(lobby, "LobbyFloor", Vector3.new(100, 2, 100), Vector3.new(0, 0, 0),
        Color3.fromRGB(45, 55, 75), Enum.Material.Slate)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "LobbySpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Config.LOBBY_SPAWN - Vector3.new(0, 4, 0)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Color = Color3.fromRGB(70, 190, 130)
    spawn.Parent = lobby

    makePart(lobby, "WelcomePlatform", Vector3.new(24, 2, 12), Vector3.new(0, 5, -25),
        Color3.fromRGB(65, 115, 190), Enum.Material.SmoothPlastic)
end

local function teleportToLobby(player)
    local character = player.Character
    if character then
        character:PivotTo(CFrame.new(Config.LOBBY_SPAWN))
    end
end

local function loadStats(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = leaderstats

    local wins = Instance.new("IntValue")
    wins.Name = "Wins"
    wins.Value = 0
    wins.Parent = leaderstats

    local success, data = pcall(function()
        return statsStore:GetAsync(tostring(player.UserId))
    end)

    if success and type(data) == "table" then
        coins.Value = tonumber(data.Coins) or 0
        wins.Value = tonumber(data.Wins) or 0
    end
end

local function saveStats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end

    local coins = leaderstats:FindFirstChild("Coins")
    local wins = leaderstats:FindFirstChild("Wins")
    local data = {
        Coins = coins and coins.Value or 0,
        Wins = wins and wins.Value or 0,
    }

    pcall(function()
        statsStore:SetAsync(tostring(player.UserId), data)
    end)
end

local function reward(player, amount, won)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end

    local coins = leaderstats:FindFirstChild("Coins")
    local wins = leaderstats:FindFirstChild("Wins")
    if coins then
        coins.Value += amount
    end
    if won and wins then
        wins.Value += 1
    end
end

local function buildArena()
    arenaFolder:ClearAllChildren()

    local center = Config.ARENA_CENTER
    makePart(arenaFolder, "ArenaBase", Vector3.new(130, 4, 130),
        center + Vector3.new(0, -18, 0), Color3.fromRGB(65, 70, 78), Enum.Material.Rock)

    -- A deliberately simple first arena: large platforms, small stepping stones and towers.
    local platforms = {
        {Vector3.new(0, 5, 0), Vector3.new(24, 3, 24)},
        {Vector3.new(-25, 8, -18), Vector3.new(16, 3, 16)},
        {Vector3.new(25, 10, -18), Vector3.new(16, 3, 16)},
        {Vector3.new(-25, 13, 20), Vector3.new(14, 3, 14)},
        {Vector3.new(25, 15, 20), Vector3.new(14, 3, 14)},
        {Vector3.new(0, 19, -38), Vector3.new(18, 3, 18)},
        {Vector3.new(0, 22, 38), Vector3.new(18, 3, 18)},
        {Vector3.new(-42, 18, 0), Vector3.new(12, 3, 12)},
        {Vector3.new(42, 21, 0), Vector3.new(12, 3, 12)},
    }

    for index, item in ipairs(platforms) do
        local offset, size = item[1], item[2]
        local color = index % 2 == 0 and Color3.fromRGB(70, 145, 190) or Color3.fromRGB(95, 115, 145)
        makePart(arenaFolder, "Platform_" .. index, size, center + offset, color, Enum.Material.Metal)
    end

    for index = 1, 8 do
        local angle = (math.pi * 2 / 8) * index
        local offset = Vector3.new(math.cos(angle) * 52, 3 + (index % 3) * 3, math.sin(angle) * 52)
        makePart(arenaFolder, "Pillar_" .. index, Vector3.new(8, 12 + (index % 3) * 4, 8),
            center + offset, Color3.fromRGB(105, 95, 85), Enum.Material.Concrete)
    end

    local lava = makePart(arenaFolder, "RisingLava", Vector3.new(150, 2, 150),
        center + Vector3.new(0, Config.LAVA_START_Y, 0),
        Color3.fromRGB(255, 75, 15), Enum.Material.Neon)
    lava.Transparency = 0.12
    lava.CanCollide = false
    lava.CanTouch = true

    local touched = {}
    lava.Touched:Connect(function(hit)
        local character = hit:FindFirstAncestorOfClass("Model")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local player = character and Players:GetPlayerFromCharacter(character)
        if humanoid and player and alive[player] and not touched[player] then
            touched[player] = true
            humanoid.Health = 0
            task.delay(1, function()
                touched[player] = nil
            end)
        end
    end)

    return lava
end

local function countAlive()
    local count = 0
    local lastPlayer = nil
    for player, isAlive in pairs(alive) do
        if isAlive and player.Parent == Players then
            count += 1
            lastPlayer = player
        end
    end
    return count, lastPlayer
end

local function sendState(phase, message, timeLeft, aliveCount)
    roundState:FireAllClients({
        Phase = phase,
        Message = message,
        TimeLeft = timeLeft or 0,
        Alive = aliveCount or 0,
    })
end

local function preparePlayer(player)
    local character = player.Character
    if not character then
        character = player.CharacterAdded:Wait()
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Health = humanoid.MaxHealth
    end
    return character
end

local function runRound()
    local participants = Players:GetPlayers()
    if #participants < Config.MIN_PLAYERS then
        return
    end

    local lava = buildArena()
    alive = {}
    roundActive = true

    for index, player in ipairs(participants) do
        local character = preparePlayer(player)
        alive[player] = true
        local angle = (math.pi * 2 / math.max(#participants, 1)) * (index - 1)
        local spawnOffset = Vector3.new(math.cos(angle) * 10, 13, math.sin(angle) * 10)
        character:PivotTo(CFrame.new(Config.ARENA_CENTER + spawnOffset))

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                alive[player] = false
                task.delay(2, function()
                    if player.Parent == Players then
                        teleportToLobby(player)
                    end
                end)
            end)
        end
    end

    local secondsSinceRise = 0
    for remaining = Config.ROUND_SECONDS, 1, -1 do
        local aliveCount, lastPlayer = countAlive()
        if aliveCount <= 1 and remaining < Config.ROUND_SECONDS - 5 then
            if aliveCount == 1 and lastPlayer then
                reward(lastPlayer, Config.WIN_REWARD, true)
                sendState("Winner", lastPlayer.DisplayName .. " победил!", 0, 1)
            else
                sendState("Finished", "Никто не выжил", 0, 0)
            end
            break
        end

        sendState("Round", "ЛАВА ПОДНИМАЕТСЯ!", remaining, aliveCount)
        task.wait(1)
        secondsSinceRise += 1
        if secondsSinceRise >= Config.LAVA_RISE_INTERVAL then
            lava.Position += Vector3.new(0, Config.LAVA_RISE_AMOUNT, 0)
            secondsSinceRise -= Config.LAVA_RISE_INTERVAL
        end
    end

    if roundActive then
        local aliveCount, lastPlayer = countAlive()
        if aliveCount == 1 and lastPlayer then
            reward(lastPlayer, Config.WIN_REWARD, true)
            sendState("Winner", lastPlayer.DisplayName .. " победил!", 0, 1)
        else
            sendState("Finished", "Раунд завершён", 0, aliveCount)
        end
    end

    roundActive = false
    for player in pairs(alive) do
        if player.Parent == Players then
            reward(player, Config.PARTICIPATION_REWARD, false)
            teleportToLobby(player)
        end
    end
    alive = {}
    task.wait(5)
    arenaFolder:ClearAllChildren()
end

Players.PlayerAdded:Connect(function(player)
    loadStats(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.25)
        if not (roundActive and alive[player]) then
            teleportToLobby(player)
        end
    end)
    if player.Character then
        teleportToLobby(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    alive[player] = nil
    saveStats(player)
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        saveStats(player)
    end
end)

buildLobby()

for _, player in ipairs(Players:GetPlayers()) do
    if not player:FindFirstChild("leaderstats") then
        loadStats(player)
    end
end

while true do
    while #Players:GetPlayers() < Config.MIN_PLAYERS do
        sendState("Waiting", "Ожидание игроков", 0, 0)
        task.wait(2)
    end

    for remaining = Config.INTERMISSION_SECONDS, 1, -1 do
        sendState("Intermission", "Следующий раунд скоро начнётся", remaining, 0)
        task.wait(1)
    end

    runRound()
end