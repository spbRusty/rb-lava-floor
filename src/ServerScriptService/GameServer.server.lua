local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local statsStore = DataStoreService:GetDataStore("FloorIsLava_PlayerStats_v1")

local function getOrCreate(parent, className, name)
    local object = parent:FindFirstChild(name)
    if not object then
        object = Instance.new(className)
        object.Name = name
        object.Parent = parent
    end
    return object
end

local remotes = getOrCreate(ReplicatedStorage, "Folder", "Remotes")
local roundState = getOrCreate(remotes, "RemoteEvent", "RoundState")
local world = getOrCreate(workspace, "Folder", "FloorIsLavaWorld")
local lobby = getOrCreate(world, "Folder", "Lobby")
local arenaFolder = getOrCreate(world, "Folder", "Arena")

local alive = {}
local participants = {}
local roundActive = false
local currentMapName = "Volcano Heights"

local PALETTE = {
    dark = Color3.fromRGB(24, 31, 45),
    slate = Color3.fromRGB(48, 61, 80),
    steel = Color3.fromRGB(87, 112, 139),
    blue = Color3.fromRGB(56, 151, 205),
    cyan = Color3.fromRGB(78, 218, 232),
    orange = Color3.fromRGB(255, 112, 44),
    gold = Color3.fromRGB(255, 193, 78),
    red = Color3.fromRGB(231, 64, 42),
    cream = Color3.fromRGB(222, 224, 218),
}

local function makePart(parent, name, size, position, color, material, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    if shape then part.Shape = shape end
    part.Parent = parent
    return part
end

local function addNeonTrim(parent, name, size, position, color)
    local trim = makePart(parent, name, size, position, color, Enum.Material.Neon)
    trim.CanCollide = false
    trim.CastShadow = false
    return trim
end

local function addSign(parent, name, text, position, size, color, rotation, face)
    local board = makePart(parent, name, size, position, PALETTE.dark, Enum.Material.Metal)
    if rotation then board.CFrame = CFrame.new(position) * rotation end
    board.CanCollide = false
    local surface = Instance.new("SurfaceGui")
    surface.Name = "SignGui"
    surface.Face = face or Enum.NormalId.Back
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 45
    surface.Parent = board

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.Text = text
    label.TextColor3 = color
    label.TextScaled = true
    label.TextStrokeTransparency = 0.75
    label.Parent = surface
    return board
end

local function setupLighting()
    Lighting.ClockTime = 17.8
    Lighting.Brightness = 2.2
    Lighting.Ambient = Color3.fromRGB(104, 116, 145)
    Lighting.OutdoorAmbient = Color3.fromRGB(125, 133, 153)
    Lighting.EnvironmentDiffuseScale = 0.35
    Lighting.EnvironmentSpecularScale = 0.55
    Lighting.GlobalShadows = true

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Density = 0.28
    atmosphere.Offset = 0.12
    atmosphere.Color = Color3.fromRGB(193, 204, 224)
    atmosphere.Decay = Color3.fromRGB(104, 78, 72)
    atmosphere.Glare = 0.25
    atmosphere.Haze = 1.2
    atmosphere.Parent = Lighting

    local grade = Lighting:FindFirstChild("LavaColorGrade") or Instance.new("ColorCorrectionEffect")
    grade.Name = "LavaColorGrade"
    grade.Brightness = 0.015
    grade.Contrast = 0.12
    grade.Saturation = 0.08
    grade.TintColor = Color3.fromRGB(255, 235, 220)
    grade.Parent = Lighting

    local bloom = Lighting:FindFirstChild("LavaBloom") or Instance.new("BloomEffect")
    bloom.Name = "LavaBloom"
    bloom.Intensity = 0.35
    bloom.Size = 28
    bloom.Threshold = 1.15
    bloom.Parent = Lighting
end

local function buildLobby()
    lobby:ClearAllChildren()

    makePart(lobby, "LobbyFloor", Vector3.new(150, 4, 150), Vector3.new(0, -2, 0), PALETTE.dark, Enum.Material.Slate)
    makePart(lobby, "CentralStage", Vector3.new(48, 3, 34), Vector3.new(0, 1, -27), PALETTE.slate, Enum.Material.Metal)
    addNeonTrim(lobby, "StageFrontGlow", Vector3.new(48, 0.35, 0.45), Vector3.new(0, 2.7, -44), PALETTE.orange)
    addSign(lobby, "MainTitle", "FLOOR  IS  LAVA", Vector3.new(0, 17, -48), Vector3.new(42, 10, 1), PALETTE.orange)
    addSign(lobby, "SubTitle", "CLIMB  •  SURVIVE  •  WIN", Vector3.new(0, 10, -48), Vector3.new(30, 3, 1), PALETTE.cream)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "LobbySpawn"
    spawn.Size = Vector3.new(14, 1, 14)
    spawn.Position = Config.LOBBY_SPAWN - Vector3.new(0, 4, 0)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Color = PALETTE.cyan
    spawn.Material = Enum.Material.Neon
    spawn.Parent = lobby

    for index = 1, 4 do
        local x = (index % 2 == 0 and 1 or -1) * 58
        local z = index <= 2 and -42 or 42
        makePart(lobby, "LobbyPillar_" .. index, Vector3.new(7, 28, 7), Vector3.new(x, 12, z), PALETTE.slate, Enum.Material.Metal)
        addNeonTrim(lobby, "PillarGlow_" .. index, Vector3.new(7.2, 0.45, 7.2), Vector3.new(x, 25.8, z), index % 2 == 0 and PALETTE.cyan or PALETTE.orange)
        local light = Instance.new("PointLight")
        light.Color = index % 2 == 0 and PALETTE.cyan or PALETTE.orange
        light.Range = 22
        light.Brightness = 1.2
        light.Parent = lobby:FindFirstChild("PillarGlow_" .. index)
    end

    for index = 1, 8 do
        local angle = math.pi * 2 * index / 8
        local x, z = math.cos(angle) * 64, math.sin(angle) * 64
        local pad = makePart(lobby, "OuterPad_" .. index, Vector3.new(10, 1, 10), Vector3.new(x, 0, z), PALETTE.steel, Enum.Material.Metal)
        addNeonTrim(lobby, "OuterPadGlow_" .. index, Vector3.new(10.1, 0.22, 0.22), Vector3.new(x, 0.65, z - 4.8), PALETTE.cyan)
    end

    addSign(lobby, "RulesBoard", "STAY ABOVE THE LAVA", Vector3.new(-48, 8, -4), Vector3.new(1, 10, 24), PALETTE.gold, CFrame.Angles(0, math.rad(-90), 0), Enum.NormalId.Front)
    addSign(lobby, "RewardsBoard", "WIN  +50 COINS", Vector3.new(48, 8, -4), Vector3.new(1, 10, 24), PALETTE.green, CFrame.Angles(0, math.rad(90), 0), Enum.NormalId.Front)
end

local function teleportToLobby(player)
    local character = player.Character
    if character then
        character:PivotTo(CFrame.new(Config.LOBBY_SPAWN + Vector3.new(0, 2, 0)))
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
        return statsStore:GetAsync("player_" .. player.UserId)
    end)
    if success and type(data) == "table" then
        coins.Value = math.max(0, tonumber(data.Coins) or 0)
        wins.Value = math.max(0, tonumber(data.Wins) or 0)
    elseif not success then
        warn("Could not load FloorIsLava stats for " .. player.Name)
    end
end

local function saveStats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local coins = leaderstats:FindFirstChild("Coins")
    local wins = leaderstats:FindFirstChild("Wins")
    local data = {
        Coins = coins and coins.Value or 0,
        Wins = wins and wins.Value or 0,
    }
    local success, err = pcall(function()
        statsStore:UpdateAsync("player_" .. player.UserId, function()
            return data
        end)
    end)
    if not success then warn("Could not save FloorIsLava stats: " .. tostring(err)) end
end

local function reward(player, amount, won)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local coins = leaderstats:FindFirstChild("Coins")
    local wins = leaderstats:FindFirstChild("Wins")
    if coins then coins.Value += amount end
    if won and wins then wins.Value += 1 end
end

local MAPS = {
    {
        Name = "Volcano Heights",
        Accent = PALETTE.orange,
        Platforms = {
            {0, 5, 0, 24, 3, 24}, {-25, 8, -18, 16, 3, 16}, {25, 10, -18, 16, 3, 16},
            {-25, 13, 20, 14, 3, 14}, {25, 15, 20, 14, 3, 14}, {0, 19, -38, 18, 3, 18},
            {0, 22, 38, 18, 3, 18}, {-42, 18, 0, 12, 3, 12}, {42, 21, 0, 12, 3, 12},
            {-12, 27, -58, 12, 3, 12}, {16, 31, 58, 12, 3, 12},
        },
    },
    {
        Name = "Neon Foundry",
        Accent = PALETTE.cyan,
        Platforms = {
            {0, 5, 0, 28, 3, 18}, {-30, 9, 0, 16, 3, 16}, {30, 9, 0, 16, 3, 16},
            {-20, 14, -27, 18, 3, 12}, {20, 17, 27, 18, 3, 12}, {0, 21, -48, 14, 3, 14},
            {0, 24, 48, 14, 3, 14}, {-48, 19, -25, 12, 3, 12}, {48, 22, 25, 12, 3, 12},
            {-4, 29, 0, 12, 3, 12}, {0, 33, 65, 12, 3, 12},
        },
    },
    {
        Name = "Skyline Ruins",
        Accent = PALETTE.gold,
        Platforms = {
            {0, 5, 0, 20, 3, 20}, {-24, 8, -24, 14, 3, 14}, {24, 11, -24, 14, 3, 14},
            {-42, 14, 0, 12, 3, 12}, {42, 16, 0, 12, 3, 12}, {-24, 19, 24, 14, 3, 14},
            {24, 22, 24, 14, 3, 14}, {0, 26, -48, 16, 3, 16}, {0, 30, 48, 16, 3, 16},
            {-48, 25, 42, 10, 3, 10}, {48, 29, -42, 10, 3, 10},
        },
    },
}

local function buildArena()
    arenaFolder:ClearAllChildren()
    local map = MAPS[math.random(1, #MAPS)]
    currentMapName = map.Name
    local center = Config.ARENA_CENTER
    local accent = map.Accent

    makePart(arenaFolder, "ArenaFoundation", Vector3.new(154, 5, 154), center + Vector3.new(0, -20, 0), PALETTE.dark, Enum.Material.Basalt)
    addNeonTrim(arenaFolder, "FoundationRing", Vector3.new(156, 0.5, 156), center + Vector3.new(0, -17.2, 0), accent)

    for index, item in ipairs(map.Platforms) do
        local x, y, z, sx, sy, sz = table.unpack(item)
        local platform = makePart(arenaFolder, "Platform_" .. index, Vector3.new(sx, sy, sz), center + Vector3.new(x, y, z), index % 2 == 0 and PALETTE.steel or PALETTE.slate, Enum.Material.Metal)
        platform.TopSurface = Enum.SurfaceType.Smooth
        addNeonTrim(arenaFolder, "PlatformEdge_" .. index, Vector3.new(sx + 0.25, 0.22, 0.28), center + Vector3.new(x, y - sy / 2 + 0.08, z - sz / 2), accent)
    end

    for index = 1, 10 do
        local angle = math.pi * 2 * index / 10
        local offset = Vector3.new(math.cos(angle) * 63, 1 + (index % 3) * 3, math.sin(angle) * 63)
        local height = 12 + (index % 3) * 5
        local tower = makePart(arenaFolder, "Tower_" .. index, Vector3.new(7, height, 7), center + offset, PALETTE.slate, Enum.Material.Concrete)
        addNeonTrim(arenaFolder, "TowerCap_" .. index, Vector3.new(7.3, 0.35, 7.3), tower.Position + Vector3.new(0, height / 2, 0), accent)
    end

    -- Moving sweepers: simple geometry, but they force players to time their jumps.
    for hazardIndex = 2, 3 do
        local item = map.Platforms[hazardIndex]
        local x, y, z, sx, sy, sz = table.unpack(item)
        local beamLength = math.max(8, math.min(sx, sz) * 0.86)
        local beamPosition = center + Vector3.new(x, y + sy / 2 + 1.25, z)
        local beam = makePart(
            arenaFolder,
            "Sweeper_" .. hazardIndex,
            Vector3.new(beamLength, 0.65, 2.1),
            beamPosition,
            PALETTE.red,
            Enum.Material.Neon
        )
        beam.CanCollide = false
        beam.CanTouch = true
        beam.CastShadow = false

        local beamLight = Instance.new("PointLight")
        beamLight.Color = PALETTE.orange
        beamLight.Range = 12
        beamLight.Brightness = 0.7
        beamLight.Parent = beam

        beam.Touched:Connect(function(hit)
            local character = hit:FindFirstAncestorOfClass("Model")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local player = character and Players:GetPlayerFromCharacter(character)
            if humanoid and player and alive[player] then
                humanoid.Health = 0
            end
        end)

        local startCFrame = beam.CFrame
        local spin = TweenService:Create(
            beam,
            TweenInfo.new(4.5 + hazardIndex * 0.7, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            { CFrame = startCFrame * CFrame.Angles(0, math.rad(360), 0) }
        )
        spin:Play()
    end

    addSign(arenaFolder, "MapName", map.Name:upper(), center + Vector3.new(0, 38, -73), Vector3.new(32, 5, 1), accent)

    local lava = makePart(arenaFolder, "RisingLava", Vector3.new(170, 3, 170), center + Vector3.new(0, Config.LAVA_START_Y, 0), PALETTE.orange, Enum.Material.Neon)
    lava.Transparency = 0.08
    lava.CanCollide = false
    lava.CanTouch = true
    lava.CastShadow = false

    local glow = Instance.new("PointLight")
    glow.Color = PALETTE.orange
    glow.Range = 65
    glow.Brightness = 2.5
    glow.Parent = lava

    local sparks = Instance.new("ParticleEmitter")
    sparks.Name = "LavaSparks"
    sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparks.Color = ColorSequence.new(PALETTE.gold, PALETTE.orange)
    sparks.LightEmission = 0.9
    sparks.Rate = 22
    sparks.Lifetime = NumberRange.new(0.7, 1.5)
    sparks.Speed = NumberRange.new(3, 8)
    sparks.SpreadAngle = Vector2.new(180, 180)
    sparks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(1, 0),
    })
    sparks.Parent = lava

    local touched = {}
    lava.Touched:Connect(function(hit)
        local character = hit:FindFirstAncestorOfClass("Model")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local player = character and Players:GetPlayerFromCharacter(character)
        if humanoid and player and alive[player] and not touched[player] then
            touched[player] = true
            humanoid.Health = 0
            task.delay(1, function() touched[player] = nil end)
        end
    end)

    return lava
end

local function countAlive()
    local count, lastPlayer = 0, nil
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
        Map = currentMapName,
    })
end

local function preparePlayer(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    if humanoid then humanoid.Health = humanoid.MaxHealth end
    return character
end

local function runRound()
    local roster = Players:GetPlayers()
    if #roster < Config.MIN_PLAYERS then return end

    local lava = buildArena()
    alive = {}
    participants = {}
    roundActive = true

    for index, player in ipairs(roster) do
        participants[player] = true
        alive[player] = true
        local character = preparePlayer(player)
        local angle = math.pi * 2 * (index - 1) / math.max(#roster, 1)
        local spawnOffset = Vector3.new(math.cos(angle) * 11, 14, math.sin(angle) * 11)
        character:PivotTo(CFrame.new(Config.ARENA_CENTER + spawnOffset))

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                alive[player] = false
                task.delay(2, function()
                    if player.Parent == Players then teleportToLobby(player) end
                end)
            end)
        end
    end

    sendState("Round", "MAP: " .. currentMapName, Config.ROUND_SECONDS, countAlive())
    local secondsSinceRise = 0
    local winnerPaid = false
    local finished = false

    for remaining = Config.ROUND_SECONDS, 1, -1 do
        local aliveCount, lastPlayer = countAlive()
        if aliveCount <= 1 and remaining < Config.ROUND_SECONDS - 4 then
            if aliveCount == 1 and lastPlayer then
                reward(lastPlayer, Config.WIN_REWARD, true)
                winnerPaid = true
                sendState("Winner", lastPlayer.DisplayName .. " WINS!", 0, 1)
            else
                sendState("Finished", "Nobody survived this round.", 0, 0)
            end
            finished = true
            break
        end

        sendState("Round", "THE LAVA IS RISING!", remaining, aliveCount)
        task.wait(1)
        secondsSinceRise += 1
        if secondsSinceRise >= Config.LAVA_RISE_INTERVAL then
            local target = lava.Position + Vector3.new(0, Config.LAVA_RISE_AMOUNT, 0)
            TweenService:Create(lava, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = target }):Play()
            secondsSinceRise = 0
        end
    end

    if not finished then
        local aliveCount, lastPlayer = countAlive()
        if aliveCount == 1 and lastPlayer and not winnerPaid then
            reward(lastPlayer, Config.WIN_REWARD, true)
            sendState("Winner", lastPlayer.DisplayName .. " WINS!", 0, 1)
        elseif aliveCount > 1 then
            sendState("Finished", "Time's up! Multiple survivors.", 0, aliveCount)
        else
            sendState("Finished", "Nobody survived this round.", 0, 0)
        end
    end

    roundActive = false
    for player in pairs(participants) do
        if player.Parent == Players then
            reward(player, Config.PARTICIPATION_REWARD, false)
            teleportToLobby(player)
        end
    end
    alive = {}
    participants = {}
    task.wait(Config.POST_ROUND_SECONDS)
    arenaFolder:ClearAllChildren()
end

Players.PlayerAdded:Connect(function(player)
    loadStats(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.25)
        if not (roundActive and alive[player]) then teleportToLobby(player) end
    end)
    if player.Character then teleportToLobby(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    alive[player] = nil
    participants[player] = nil
    saveStats(player)
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do saveStats(player) end
end)

setupLighting()
buildLobby()

for _, player in ipairs(Players:GetPlayers()) do
    if not player:FindFirstChild("leaderstats") then loadStats(player) end
end

while true do
    while #Players:GetPlayers() < Config.MIN_PLAYERS do
        sendState("Waiting", "WAITING FOR PLAYERS", 0, 0)
        task.wait(2)
    end

    for remaining = Config.INTERMISSION_SECONDS, 1, -1 do
        sendState("Intermission", "NEXT ROUND STARTS SOON", remaining, 0)
        task.wait(1)
    end

    runRound()
end
