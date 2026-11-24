local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))
local ArenaModule = require(script.Parent:WaitForChild("Modules"):WaitForChild("Arena"))
local BotsModule = require(script.Parent:WaitForChild("Modules"):WaitForChild("Bots"))

local function playSound(assetId, volume, parent)
	return Sounds.play(assetId, volume, parent)
end

local function getStore(kind, name)
    local ok, store = pcall(function()
        if kind == "ordered" then
            return DataStoreService:GetOrderedDataStore(name)
        end
        return DataStoreService:GetDataStore(name)
    end)
    if ok and store then return store end
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
local shopPurchase = getOrCreate(remotes, "RemoteFunction", "ShopPurchase")
local shopCatalog = getOrCreate(remotes, "RemoteFunction", "ShopCatalog")
local world = getOrCreate(workspace, "Folder", "FloorIsLavaWorld")
local lobby = getOrCreate(world, "Folder", "Lobby")
local arenaFolder = getOrCreate(world, "Folder", "Arena")
local botFolder = getOrCreate(world, "Folder", "Bots")

local alive = {}
local participants = {}
local roundActive = false
local currentMapName = "GENERATED SECTOR"
local currentModifier = Config.MODIFIERS[1]
local botByModel = {}
local generatedPlatforms = {}
local lastLayoutSignature = nil
local secondChanceReady = {}
local ownedBuffs = {} -- [player] = { [itemId] = true }

local PALETTE = {
    dark = Color3.fromRGB(38, 55, 92),
    slate = Color3.fromRGB(62, 91, 139),
    steel = Color3.fromRGB(91, 157, 205),
    blue = Color3.fromRGB(42, 145, 232),
    cyan = Color3.fromRGB(65, 225, 245),
    orange = Color3.fromRGB(255, 126, 38),
    gold = Color3.fromRGB(255, 215, 62),
    green = Color3.fromRGB(104, 224, 91),
    red = Color3.fromRGB(255, 65, 76),
    cream = Color3.fromRGB(255, 246, 220),
    purple = Color3.fromRGB(153, 105, 235),
    pink = Color3.fromRGB(255, 105, 180),
    lime = Color3.fromRGB(177, 238, 66),
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
    Lighting.ClockTime = 14.2
    Lighting.Brightness = 3
    Lighting.Ambient = Color3.fromRGB(145, 159, 190)
    Lighting.OutdoorAmbient = Color3.fromRGB(165, 178, 205)
    Lighting.EnvironmentDiffuseScale = 0.55
    Lighting.EnvironmentSpecularScale = 0.65
    Lighting.GlobalShadows = true
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Density = 0.16
    atmosphere.Offset = 0.18
    atmosphere.Color = Color3.fromRGB(210, 230, 255)
    atmosphere.Decay = Color3.fromRGB(120, 155, 205)
    atmosphere.Glare = 0.12
    atmosphere.Haze = 0.55
    atmosphere.Parent = Lighting
end

local function pickModifier()
    local mods = Config.MODIFIERS
    local total = 0
    for _, m in ipairs(mods) do total += (m.Weight or 1) end
    local r = Random.new():NextNumber(0, total)
    local acc = 0
    for _, m in ipairs(mods) do
        acc += (m.Weight or 1)
        if r <= acc then return m end
    end
    return mods[1]
end

local function sendState(extra)
    local payload = {
        Phase = extra and extra.Phase or (roundActive and "Round" or "Intermission"),
        Message = extra and extra.Message or "",
        TimeLeft = extra and extra.TimeLeft,
        MapName = currentMapName,
        Modifier = currentModifier and currentModifier.Name or "STANDARD",
        ModifierDescription = currentModifier and currentModifier.Description or "",
    }
    for k, v in pairs(extra or {}) do payload[k] = v end
    roundState:FireAllClients(payload)
end

local function countAlive()
    local n = 0
    for _ in pairs(alive) do n += 1 end
    return n
end

-- Shared context for modules
local gameCtx = {
    Config = Config,
    PALETTE = PALETTE,
    makePart = makePart,
    addNeonTrim = addNeonTrim,
    addSign = addSign,
    playSound = playSound,
    arenaFolder = arenaFolder,
    botFolder = botFolder,
    generatedPlatforms = generatedPlatforms,
    botByModel = botByModel,
    alive = alive,
    secondChanceReady = secondChanceReady,
    currentModifier = currentModifier,
    lastLayoutSignature = lastLayoutSignature,
    currentMapName = currentMapName,
    roundActive = false,
}

local arenaApi = ArenaModule.create(gameCtx)
local botsApi = BotsModule.create(gameCtx)

local function buildArena()
    gameCtx.currentModifier = currentModifier
    gameCtx.roundActive = roundActive
    gameCtx.secondChanceReady = secondChanceReady
    gameCtx.lastLayoutSignature = lastLayoutSignature
    gameCtx.currentMapName = currentMapName
    local lava = arenaApi.build()
    generatedPlatforms = gameCtx.generatedPlatforms
    currentMapName = gameCtx.currentMapName
    lastLayoutSignature = gameCtx.lastLayoutSignature
    return lava
end

local function createBot(index, spawnPosition)
    return botsApi.createBot(index, spawnPosition)
end

local function runBotAI(bot)
    gameCtx.roundActive = roundActive
    return botsApi.runBotAI(bot)
end

local function buildLobby()
    lobby:ClearAllChildren()
    makePart(lobby, "LobbyFloor", Vector3.new(150, 4, 150), Vector3.new(0, -2, 0), PALETTE.blue, Enum.Material.SmoothPlastic)
    makePart(lobby, "CentralStage", Vector3.new(48, 3, 34), Vector3.new(0, 1, -27), PALETTE.purple, Enum.Material.SmoothPlastic)
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
    if statsStore then
        local success, data = pcall(function() return statsStore:GetAsync("player_" .. player.UserId) end)
        if success and type(data) == "table" then
            coins.Value = math.max(0, tonumber(data.Coins) or 0)
            wins.Value = math.max(0, tonumber(data.Wins) or 0)
        end
    end
end

local function saveStats(player)
    if not statsStore then return end
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local coins = leaderstats:FindFirstChild("Coins")
    local wins = leaderstats:FindFirstChild("Wins")
    local data = { Coins = coins and coins.Value or 0, Wins = wins and wins.Value or 0 }
    pcall(function()
        statsStore:UpdateAsync("player_" .. player.UserId, function() return data end)
    end)
end

local function reward(player, amount, won)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local coins = leaderstats:FindFirstChild("Coins")
    local wins = leaderstats:FindFirstChild("Wins")
    if coins then coins.Value += amount end
    if won and wins then wins.Value += 1 end
end

-- Shop
shopCatalog.OnServerInvoke = function(player)
    local catalog = {}
    for _, item in ipairs(Config.SHOP or {}) do
        table.insert(catalog, { Id = item.Id, Name = item.Name, Price = item.Price, Description = item.Description })
    end
    local owned = ownedBuffs[player] or {}
    return catalog, owned
end

shopPurchase.OnServerInvoke = function(player, itemId)
    if type(itemId) ~= "string" then return false end
    local item
    for _, it in ipairs(Config.SHOP or {}) do
        if it.Id == itemId then item = it break end
    end
    if not item then return false end
    ownedBuffs[player] = ownedBuffs[player] or {}
    if ownedBuffs[player][itemId] then return false end
    local leaderstats = player:FindFirstChild("leaderstats")
    local coins = leaderstats and leaderstats:FindFirstChild("Coins")
    if not coins or coins.Value < item.Price then return false end
    coins.Value -= item.Price
    ownedBuffs[player][itemId] = true
    return true
end

local function runRound()
    currentModifier = pickModifier()
    gameCtx.currentModifier = currentModifier
    sendState({ Phase = "Intermission", Message = "Modifier: " .. (currentModifier.Name or "STANDARD"), TimeLeft = Config.INTERMISSION_TIME or 8 })
    task.wait(Config.INTERMISSION_TIME or 8)

    table.clear(alive)
    table.clear(participants)
    table.clear(secondChanceReady)
    local lava = buildArena()

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            alive[player] = true
            participants[player] = true
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local jumpPower = Config.PLAYER_JUMP_POWER + ((currentModifier and currentModifier.JumpPowerBonus) or 0)
                local buffs = ownedBuffs[player] or {}
                if buffs["jump"] then jumpPower += 8 end
                if buffs["speed"] then humanoid.WalkSpeed = 22 else humanoid.WalkSpeed = 16 end
                humanoid.UseJumpPower = true
                humanoid.JumpPower = jumpPower
                if buffs["second_chance"] then secondChanceReady[player] = true end
            end
            character:PivotTo(CFrame.new(Config.ARENA_CENTER + Vector3.new(0, 8, 0)))
        end
    end

    -- Spawn bots
    for index = 1, (Config.BOT_COUNT or 3) do
        local spawnPosition = Config.ARENA_CENTER + Vector3.new(Random.new():NextNumber(-6, 6), 8, Random.new():NextNumber(-6, 6))
        local bot = createBot(index, spawnPosition)
        if bot then
            alive[bot] = true
            task.spawn(function()
                while roundActive and bot.Model and bot.Model.Parent and bot.Humanoid.Health > 0 do
                    runBotAI(bot)
                    task.wait(0.15)
                end
            end)
        end
    end

    roundActive = true
    gameCtx.roundActive = true
    sendState({ Phase = "Round", Message = "Survive!", TimeLeft = Config.ROUND_TIME or 90 })

    local lavaY = lava.Position.Y
    local startTime = os.clock()
    local roundTime = Config.ROUND_TIME or 90
    while roundActive and (os.clock() - startTime) < roundTime and countAlive() > 0 do
        local riseInterval = math.max(1, Config.LAVA_RISE_INTERVAL * ((currentModifier and currentModifier.LavaIntervalMul) or 1))
        local riseAmount = Config.LAVA_RISE_AMOUNT * ((currentModifier and currentModifier.LavaAmountMul) or 1)
        task.wait(riseInterval)
        lavaY += riseAmount
        lava.Position = Vector3.new(lava.Position.X, lavaY, lava.Position.Z)
        local left = math.max(0, roundTime - (os.clock() - startTime))
        sendState({ Phase = "Round", Message = "Lava rising!", TimeLeft = math.floor(left) })
    end

    roundActive = false
    gameCtx.roundActive = false

    -- Winners
    local winners = {}
    for contestant in pairs(alive) do
        if typeof(contestant) == "Instance" and contestant:IsA("Player") then
            table.insert(winners, contestant)
            reward(contestant, Config.WIN_COINS or 50, true)
            playSound(Config.SOUND_WIN, 0.7, contestant.Character and contestant.Character:FindFirstChild("HumanoidRootPart"))
        end
    end
    for contestant in pairs(participants) do
        if typeof(contestant) == "Instance" and contestant:IsA("Player") and not alive[contestant] then
            reward(contestant, Config.PARTICIPATE_COINS or 10, false)
        end
    end

    local msg = #winners > 0 and (winners[1].Name .. (#winners > 1 and (" +" .. (#winners-1)) or "") .. " wins!") or "No survivors"
    sendState({ Phase = "Winner", Message = msg, TimeLeft = 5 })
    task.wait(5)

    for _, player in ipairs(Players:GetPlayers()) do
        teleportToLobby(player)
        ownedBuffs[player] = {}
        saveStats(player)
    end
    sendState({ Phase = "Finished", Message = "Next round soon...", TimeLeft = 3 })
    task.wait(3)
end

Players.PlayerAdded:Connect(function(player)
    loadStats(player)
    ownedBuffs[player] = {}
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if not roundActive then teleportToLobby(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    saveStats(player)
    alive[player] = nil
    ownedBuffs[player] = nil
    secondChanceReady[player] = nil
end)

setupLighting()
buildLobby()

task.spawn(function()
    while true do
        local ok, err = pcall(runRound)
        if not ok then warn("[FloorIsLava] Round error: " .. tostring(err)) end
        task.wait(1)
    end
end)
