local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- DataStores only work in a published experience with "Studio Access to API Services"
-- enabled. Fall back to nil stores so the place still runs locally in Studio.
local function getStore(kind, name)
    local ok, store = pcall(function()
        if kind == "ordered" then
            return DataStoreService:GetOrderedDataStore(name)
        end
        return DataStoreService:GetDataStore(name)
    end)
    if ok and store then
        return store
    end
    warn("[FloorIsLava] DataStore '" .. name .. "' unavailable - running without persistence.")
    return nil
end

local statsStore = getStore("regular", "FloorIsLava_PlayerStats_v1")
local winsOrderedStore = getStore("ordered", "FloorIsLava_GlobalWins_v1")

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
local currentMapName = "GENERATED SECTOR"
local botFolder = getOrCreate(world, "Folder", "Bots")
local botByModel = {}
local generatedPlatforms = {}
local lastLayoutSignature = nil

local PALETTE = {
    dark = Color3.fromRGB(24, 31, 45),
    slate = Color3.fromRGB(48, 61, 80),
    steel = Color3.fromRGB(87, 112, 139),
    blue = Color3.fromRGB(56, 151, 205),
    cyan = Color3.fromRGB(78, 218, 232),
    orange = Color3.fromRGB(255, 112, 44),
    gold = Color3.fromRGB(255, 193, 78),
    green = Color3.fromRGB(91, 225, 157),
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

local leaderboardLabels = {}

local function buildLeaderboard(parent)
    local board = makePart(parent, "GlobalLeaderboard", Vector3.new(38, 21, 1), Vector3.new(0, 10.5, 52), PALETTE.dark, Enum.Material.Metal)
    board.CanCollide = false
    addNeonTrim(parent, "LeaderboardTopGlow", Vector3.new(38, 0.35, 0.35), Vector3.new(0, 21.2, 51.35), PALETTE.gold)

    local surface = Instance.new("SurfaceGui")
    surface.Name = "GlobalWinsBoard"
    surface.Face = Enum.NormalId.Front
    surface.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    surface.CanvasSize = Vector2.new(900, 500)
    surface.Parent = board

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 76)
    title.Position = UDim2.fromOffset(20, 12)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = "GLOBAL TOP 10  •  WINS"
    title.TextColor3 = PALETTE.gold
    title.TextScaled = true
    title.Parent = surface

    if not winsOrderedStore then
        title.Text = "GLOBAL TOP 10  •  PUBLISH TO ENABLE"
    end

    for index = 1, 10 do
        local row = Instance.new("TextLabel")
        row.Name = "Rank_" .. index
        row.Size = UDim2.new(1, -56, 0, 34)
        row.Position = UDim2.fromOffset(28, 92 + (index - 1) * 38)
        row.BackgroundTransparency = 1
        row.Font = Enum.Font.GothamBold
        row.Text = winsOrderedStore and string.format("%02d     ...", index) or "PUBLISH PLACE TO ENABLE"
        row.TextColor3 = index == 1 and PALETTE.gold or PALETTE.cream
        row.TextScaled = true
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Parent = surface
        leaderboardLabels[index] = row
    end
end

local function refreshLeaderboard()
    if not winsOrderedStore then return end
    local success, pages = pcall(function()
        return winsOrderedStore:GetSortedAsync(false, 10)
    end)
    if not success then
        warn("Could not refresh global wins leaderboard: " .. tostring(pages))
        return
    end

    local page = pages:GetCurrentPage()
    for index = 1, 10 do
        local row = leaderboardLabels[index]
        local entry = page[index]
        if row then
            if entry then
                local userId = tonumber(string.match(entry.key, "^player_(%d+)$"))
                local displayName = "Player"
                if userId then
                    local nameSuccess, name = pcall(function()
                        return Players:GetNameFromUserIdAsync(userId)
                    end)
                    if nameSuccess then displayName = name end
                end
                row.Text = string.format("%02d     %s     •     %d", index, displayName, entry.value)
            else
                row.Text = string.format("%02d     —", index)
            end
        end
    end
end

local function updateGlobalWins(player, winsValue)
    if not winsOrderedStore then return end
    task.spawn(function()
        local success, err = pcall(function()
            winsOrderedStore:SetAsync("player_" .. player.UserId, winsValue)
        end)
        if not success then warn("Could not update global wins for " .. player.Name .. ": " .. tostring(err)) end
    end)
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
    buildLeaderboard(lobby)
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

    local success, data = false, nil
    if statsStore then
        success, data = pcall(function()
            return statsStore:GetAsync("player_" .. player.UserId)
        end)
    end
    if success and type(data) == "table" then
        coins.Value = math.max(0, tonumber(data.Coins) or 0)
        wins.Value = math.max(0, tonumber(data.Wins) or 0)
    elseif statsStore and not success then
        warn("Could not load FloorIsLava stats for " .. player.Name)
    end
    if success and winsOrderedStore then updateGlobalWins(player, wins.Value) end
end

local function saveStats(player)
    if not statsStore then return end
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
    if won and wins then updateGlobalWins(player, wins.Value) end
end

local function buildArena()
    arenaFolder:ClearAllChildren()
    botFolder:ClearAllChildren()
    botByModel = {}
    generatedPlatforms = {}

    local rng = Random.new()
    local laneCount = rng:NextInteger(3, 4)
    local laneSpacing = rng:NextNumber(9.8, 10.4)
    local platformWidth = rng:NextNumber(8.4, 9.0)
    local verticalStep = rng:NextNumber(3.6, 4.0)
    local layerCount = rng:NextInteger(6, 7)
    local sectorNumber = rng:NextInteger(1000, 9999)
    local signature = table.concat({laneCount, math.floor(laneSpacing * 10), math.floor(platformWidth * 10), math.floor(verticalStep * 10), layerCount, sectorNumber}, "-")
    while signature == lastLayoutSignature do
        sectorNumber = rng:NextInteger(1000, 9999)
        signature = signature .. "-" .. tostring(sectorNumber)
    end
    lastLayoutSignature = signature
    currentMapName = string.format("SECTOR %04d", sectorNumber)

    local center = Config.ARENA_CENTER
    local accentChoices = {PALETTE.orange, PALETTE.cyan, PALETTE.gold, PALETTE.green}
    local accent = accentChoices[rng:NextInteger(1, #accentChoices)]
    local rotationAngle = rng:NextNumber(0, math.pi * 2)
    local rotationCos = math.cos(rotationAngle)
    local rotationSin = math.sin(rotationAngle)

    makePart(arenaFolder, "ArenaFoundation", Vector3.new(180, 5, 180), center + Vector3.new(0, -20, 0), PALETTE.dark, Enum.Material.Basalt)
    addNeonTrim(arenaFolder, "FoundationRing", Vector3.new(182, 0.5, 182), center + Vector3.new(0, -17.2, 0), accent)

    local base = makePart(arenaFolder, "StartPlatform", Vector3.new(14, 3, 14), center + Vector3.new(0, 5, 0), PALETTE.slate, Enum.Material.Metal)
    addNeonTrim(arenaFolder, "StartPlatformGlow", Vector3.new(14.2, 0.25, 0.3), base.Position + Vector3.new(0, 1.62, -6.8), accent)
    generatedPlatforms[1] = {Part = base, Layer = 0, Lane = 0, TopY = base.Position.Y + base.Size.Y / 2}

    -- Every platform in a layer has at least two reachable choices in the next layer.
    -- Adjacent lanes are close enough for a normal Roblox jump with a modest jump-power boost.
    local previousDepth = 2.5
    for layer = 1, layerCount do
        local depth = previousDepth + rng:NextNumber(9.8, 10.4)
        previousDepth = depth
        local y = 5 + layer * verticalStep
        local layerPlatforms = {}

        for lane = 1, laneCount do
            local x = (lane - (laneCount + 1) / 2) * laneSpacing + rng:NextNumber(-0.15, 0.15)
            local z = depth + rng:NextNumber(-0.2, 0.2)
            local sizeX = platformWidth + rng:NextNumber(-0.5, 0.5)
            local sizeZ = platformWidth + rng:NextNumber(-0.5, 0.5)
            local platform = makePart(
                arenaFolder,
                string.format("Platform_L%d_%d", layer, lane),
                Vector3.new(sizeX, 2.5, sizeZ),
                center + Vector3.new(x, y, z),
                (layer + lane) % 2 == 0 and PALETTE.steel or PALETTE.slate,
                Enum.Material.Metal
            )
            platform.TopSurface = Enum.SurfaceType.Smooth
            addNeonTrim(arenaFolder, "PlatformEdgeA_L" .. layer .. "_" .. lane,
                Vector3.new(sizeX + 0.2, 0.2, 0.22),
                platform.Position + Vector3.new(0, -1.12, -sizeZ / 2), accent)
            addNeonTrim(arenaFolder, "PlatformEdgeB_L" .. layer .. "_" .. lane,
                Vector3.new(0.22, 0.2, sizeZ + 0.2),
                platform.Position + Vector3.new(-sizeX / 2, -1.12, 0), accent)

            local record = {
                Part = platform,
                Layer = layer,
                Lane = lane,
                TopY = platform.Position.Y + platform.Size.Y / 2,
            }
            generatedPlatforms[#generatedPlatforms + 1] = record
            layerPlatforms[#layerPlatforms + 1] = record
        end
    end

    -- Randomized perimeter structures make each generated sector look different without heavy assets.
    for index = 1, 8 do
        local angle = math.pi * 2 * index / 8 + rng:NextNumber(-0.12, 0.12)
        local radius = rng:NextNumber(82, 88)
        local height = rng:NextNumber(10, 24)
        local position = center + Vector3.new(math.cos(angle) * radius, height / 2 - 2, math.sin(angle) * radius)
        local tower = makePart(arenaFolder, "Tower_" .. index, Vector3.new(rng:NextNumber(4, 7), height, rng:NextNumber(4, 7)), position, PALETTE.slate, Enum.Material.Concrete)
        addNeonTrim(arenaFolder, "TowerCap_" .. index, Vector3.new(tower.Size.X + 0.3, 0.3, tower.Size.Z + 0.3), tower.Position + Vector3.new(0, height / 2, 0), accent)
    end

    -- Two rotating hazards are placed on different middle layers.
    local hazardLayers = {math.max(2, math.floor(layerCount * 0.35)), math.max(3, math.floor(layerCount * 0.7))}
    for hazardIndex, hazardLayer in ipairs(hazardLayers) do
        local candidates = {}
        for _, record in ipairs(generatedPlatforms) do
            if record.Layer == hazardLayer then table.insert(candidates, record) end
        end
        if #candidates > 0 then
            local record = candidates[rng:NextInteger(1, #candidates)]
            local platform = record.Part
            local beam = makePart(
                arenaFolder,
                "Sweeper_" .. hazardIndex,
                Vector3.new(platform.Size.X * 0.82, 0.55, 1.8),
                platform.Position + Vector3.new(0, platform.Size.Y / 2 + 1.15, 0),
                PALETTE.red,
                Enum.Material.Neon
            )
            beam.CanCollide = false
            beam.CastShadow = false
            local beamLight = Instance.new("PointLight")
            beamLight.Color = PALETTE.orange
            beamLight.Range = 10
            beamLight.Brightness = 0.65
            beamLight.Parent = beam

            beam.Touched:Connect(function(hit)
                local character = hit:FindFirstAncestorOfClass("Model")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local player = character and Players:GetPlayerFromCharacter(character)
                local bot = character and botByModel[character]
                local contestant = player or bot
                if humanoid and contestant and alive[contestant] then humanoid.Health = 0 end
            end)

            local spin = TweenService:Create(
                beam,
                TweenInfo.new(rng:NextNumber(5.2, 7.4), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
                {CFrame = beam.CFrame * CFrame.Angles(0, math.rad(359), 0)}
            )
            spin:Play()
        end
    end

    addSign(arenaFolder, "MapName", currentMapName, center + Vector3.new(0, 42, -55), Vector3.new(28, 4, 1), accent)

    local lava = makePart(arenaFolder, "RisingLava", Vector3.new(190, 3, 190), center + Vector3.new(0, Config.LAVA_START_Y, 0), PALETTE.orange, Enum.Material.Neon)
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
        local bot = character and botByModel[character]
        local contestant = player or bot
        if humanoid and contestant and alive[contestant] and not touched[contestant] then
            touched[contestant] = true
            humanoid.Health = 0
            task.delay(1, function() touched[contestant] = nil end)
        end
    end)

    return lava
end

local function createBot(index, spawnPosition)
    local model = Instance.new("Model")
    model.Name = "LavaBot_" .. index

    local function makeBodyPart(name, size, color, position, transparency)
        local part = Instance.new("Part")
        part.Name = name
        part.Size = size
        part.Color = color
        part.Material = Enum.Material.SmoothPlastic
        part.Position = position
        part.Transparency = transparency or 0
        part.Anchored = false
        part.CanCollide = false
        part.Parent = model
        return part
    end

    local root = makeBodyPart("HumanoidRootPart", Vector3.new(2, 2, 1), Color3.new(1, 1, 1), spawnPosition, 1)
    root.CanCollide = false
    local bodyColor = index % 2 == 0 and Color3.fromRGB(62, 170, 220) or Color3.fromRGB(220, 112, 62)
    local torso = makeBodyPart("Torso", Vector3.new(2, 2, 1), bodyColor, spawnPosition)
    local head = makeBodyPart("Head", Vector3.new(2, 1, 1), Color3.fromRGB(238, 202, 158), spawnPosition + Vector3.new(0, 1.5, 0))
    local leftArm = makeBodyPart("Left Arm", Vector3.new(1, 2, 1), bodyColor, spawnPosition + Vector3.new(-1.5, 0, 0))
    local rightArm = makeBodyPart("Right Arm", Vector3.new(1, 2, 1), bodyColor, spawnPosition + Vector3.new(1.5, 0, 0))
    local leftLeg = makeBodyPart("Left Leg", Vector3.new(1, 2, 1), Color3.fromRGB(42, 48, 62), spawnPosition + Vector3.new(-0.5, -2, 0))
    local rightLeg = makeBodyPart("Right Leg", Vector3.new(1, 2, 1), Color3.fromRGB(42, 48, 62), spawnPosition + Vector3.new(0.5, -2, 0))
    leftLeg.CanCollide = true
    rightLeg.CanCollide = true

    local function connect(name, part0, part1, c0, c1)
        local joint = Instance.new("Motor6D")
        joint.Name = name
        joint.Part0 = part0
        joint.Part1 = part1
        joint.C0 = c0
        joint.C1 = c1
        joint.Parent = part0
    end

    connect("RootJoint", root, torso, CFrame.new(), CFrame.new())
    connect("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    connect("Left Shoulder", torso, leftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0, 0.5, 0))
    connect("Right Shoulder", torso, rightArm, CFrame.new(1, 0.5, 0), CFrame.new(0, 0.5, 0))
    connect("Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
    connect("Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayName = "BOT " .. index
    humanoid.NameDisplayDistance = 45
    humanoid.WalkSpeed = 14 + (index % 2)
    humanoid.UseJumpPower = true
    humanoid.JumpPower = Config.PLAYER_JUMP_POWER
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.Parent = model

    model.PrimaryPart = root
    model.Parent = botFolder
    model:PivotTo(CFrame.new(spawnPosition))
    pcall(function() root:SetNetworkOwner(nil) end)
    local record = {IsBot = true, Model = model, Humanoid = humanoid, Name = "BOT " .. index}
    botByModel[model] = record
    return record
end

local function runBotAI(bot)
    task.spawn(function()
        local humanoid = bot.Humanoid
        while roundActive and alive[bot] and bot.Model.Parent and humanoid.Health > 0 do
            local root = bot.Model:FindFirstChild("HumanoidRootPart")
            if not root then break end

            local currentRecord = nil
            local bestScore = math.huge
            for _, record in ipairs(generatedPlatforms) do
                local horizontal = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(record.Part.Position.X, 0, record.Part.Position.Z)).Magnitude
                local vertical = root.Position.Y - record.TopY
                if vertical >= -1 and vertical < 8 and horizontal < 18 then
                    local score = math.abs(vertical - 3) + horizontal * 0.02
                    if score < bestScore then
                        bestScore = score
                        currentRecord = record
                    end
                end
            end

            local options = {}
            if currentRecord then
                for _, record in ipairs(generatedPlatforms) do
                    local sameNextLayer = record.Layer == currentRecord.Layer + 1
                    local connectedLane = currentRecord.Layer == 0 or math.abs(record.Lane - currentRecord.Lane) <= 1
                    if sameNextLayer and connectedLane then
                        table.insert(options, record)
                    end
                end
            end

            if #options > 0 then
                table.sort(options, function(a, b)
                    local aDistance = (Vector3.new(a.Part.Position.X, 0, a.Part.Position.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
                    local bDistance = (Vector3.new(b.Part.Position.X, 0, b.Part.Position.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
                    return aDistance < bDistance
                end)

                -- Move to the edge first, then jump across the small physical gap.
                local target = options[math.random(1, math.min(2, #options))]
                local direction = Vector3.new(
                    target.Part.Position.X - currentRecord.Part.Position.X,
                    0,
                    target.Part.Position.Z - currentRecord.Part.Position.Z
                ).Unit
                local edgeScale = (currentRecord.Part.Size.X / 2 - 0.8) / math.max(math.abs(direction.X), math.abs(direction.Z), 0.01)
                local targetScale = (target.Part.Size.X / 2 - 0.8) / math.max(math.abs(direction.X), math.abs(direction.Z), 0.01)
                local launchPoint = currentRecord.Part.Position + direction * edgeScale
                local landingPoint = target.Part.Position - direction * targetScale

                humanoid:MoveTo(Vector3.new(launchPoint.X, currentRecord.Part.Position.Y + 4.25, launchPoint.Z))
                task.wait(0.45)
                if humanoid.Health > 0 and alive[bot] then
                    humanoid.Jump = true
                    humanoid:MoveTo(Vector3.new(landingPoint.X, target.Part.Position.Y + 4.25, landingPoint.Z))
                end
                task.wait(1.25)
            else
                task.wait(0.3)
            end
        end
    end)
end

local function countAlive()
    local count, lastContestant = 0, nil
    for contestant, isAlive in pairs(alive) do
        local present = false
        if type(contestant) == "table" and contestant.IsBot then
            present = contestant.Model and contestant.Model.Parent ~= nil
        else
            present = contestant.Parent == Players
        end
        if isAlive and present then
            count += 1
            lastContestant = contestant
        end
    end
    return count, lastContestant
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

    local contestants = {}
    for index, player in ipairs(roster) do
        participants[player] = true
        alive[player] = true
        table.insert(contestants, player)

        local character = preparePlayer(player)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = Config.PLAYER_JUMP_POWER
        end
        local angle = math.pi * 2 * (index - 1) / math.max(#roster, 1)
        local spawnOffset = Vector3.new(math.cos(angle) * 5, 9.5, math.sin(angle) * 5)
        character:PivotTo(CFrame.new(Config.ARENA_CENTER + spawnOffset))

        if humanoid then
            humanoid.Died:Connect(function()
                alive[player] = false
                task.delay(2, function()
                    if player.Parent == Players then teleportToLobby(player) end
                end)
            end)
        end
    end

    if #roster == 1 then
        for index = 1, Config.SOLO_BOT_COUNT do
            local angle = math.pi * 2 * index / (Config.SOLO_BOT_COUNT + 1)
            local spawnPosition = Config.ARENA_CENTER + Vector3.new(math.cos(angle) * 6, 9.5, math.sin(angle) * 6)
            local bot = createBot(index, spawnPosition)
            alive[bot] = true
            table.insert(contestants, bot)
            bot.Humanoid.Died:Connect(function()
                alive[bot] = false
            end)
            runBotAI(bot)
        end
    end

    sendState("Round", "MAP: " .. currentMapName, Config.ROUND_SECONDS, countAlive())
    local secondsSinceRise = 0
    local winnerPaid = false
    local finished = false

    for remaining = Config.ROUND_SECONDS, 1, -1 do
        local aliveCount, lastContestant = countAlive()
        if aliveCount <= 1 and remaining < Config.ROUND_SECONDS - 4 then
            if aliveCount == 1 and lastContestant then
                if typeof(lastContestant) == "Instance" and lastContestant:IsA("Player") then
                    reward(lastContestant, Config.WIN_REWARD, true)
                    winnerPaid = true
                    sendState("Winner", lastContestant.DisplayName .. " WINS!", 0, 1)
                else
                    sendState("Winner", lastContestant.Name .. " WINS!", 0, 1)
                end
            else
                sendState("Finished", "Nobody survived this round.", 0, 0)
            end
            finished = true
            break
        end

        sendState("Round", "DODGE THE SWEEPERS  •  THE LAVA IS RISING!", remaining, aliveCount)
        task.wait(1)
        secondsSinceRise += 1
        if secondsSinceRise >= Config.LAVA_RISE_INTERVAL then
            local target = lava.Position + Vector3.new(0, Config.LAVA_RISE_AMOUNT, 0)
            TweenService:Create(lava, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = target}):Play()
            secondsSinceRise = 0
        end
    end

    if not finished then
        local aliveCount, lastContestant = countAlive()
        if aliveCount == 1 and lastContestant then
            if typeof(lastContestant) == "Instance" and lastContestant:IsA("Player") and not winnerPaid then
                reward(lastContestant, Config.WIN_REWARD, true)
            end
            sendState("Winner", lastContestant.Name .. " WINS!", 0, 1)
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
    for contestant in pairs(alive) do
        if type(contestant) == "table" and contestant.IsBot then
            botByModel[contestant.Model] = nil
            if contestant.Model then contestant.Model:Destroy() end
        end
    end
    alive = {}
    participants = {}
    botByModel = {}
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
task.spawn(function()
    while true do
        refreshLeaderboard()
        task.wait(60)
    end
end)

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
