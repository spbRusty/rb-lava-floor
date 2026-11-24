--[[ Arena generation - extracted from GameServer ]]
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local Arena = {}

function Arena.create(ctx)
	local Config = ctx.Config
	local PALETTE = ctx.PALETTE
	local makePart = ctx.makePart
	local addNeonTrim = ctx.addNeonTrim
	local addSign = ctx.addSign
	local playSound = ctx.playSound
	local arenaFolder = ctx.arenaFolder
	local botFolder = ctx.botFolder

local function buildArena()
	local currentModifier = ctx.currentModifier
	local lastLayoutSignature = ctx.lastLayoutSignature
	local generatedPlatforms = ctx.generatedPlatforms
	local botByModel = ctx.botByModel
	local alive = ctx.alive
	local secondChanceReady = ctx.secondChanceReady
	local countAlive = ctx.countAlive
	local sendState = ctx.sendState
	local currentMapName = ctx.currentMapName

    arenaFolder:ClearAllChildren()
    botFolder:ClearAllChildren()
    table.clear(botByModel)
    table.clear(generatedPlatforms)

    local mod = currentModifier or Config.MODIFIERS[1]
    local rng = Random.new()
    local laneCount = rng:NextInteger(3, 4)
    local platformScale = mod.PlatformScale or 1
    local layerCount = rng:NextInteger(6, 7) + (mod.LayerBonus or 0)
    local sectorNumber = rng:NextInteger(1000, 9999)
    local signature = table.concat({laneCount, layerCount, sectorNumber, mod.Id or "std"}, "-")
    while signature == lastLayoutSignature do
        sectorNumber = rng:NextInteger(1000, 9999)
        signature = signature .. "-" .. tostring(sectorNumber)
    end
    lastLayoutSignature = signature
    currentMapName = string.format("SECTOR %04d", sectorNumber)

    local center = Config.ARENA_CENTER
    local accentChoices = {PALETTE.orange, PALETTE.cyan, PALETTE.gold, PALETTE.green, PALETTE.purple, PALETTE.pink}
    local accent = accentChoices[rng:NextInteger(1, #accentChoices)]
    local rotationAngle = rng:NextNumber(0, math.pi * 2)

    makePart(arenaFolder, "ArenaFoundation", Vector3.new(180, 5, 180), center + Vector3.new(0, -20, 0), Color3.fromRGB(55, 74, 120), Enum.Material.Slate)
    addNeonTrim(arenaFolder, "FoundationRing", Vector3.new(182, 0.5, 182), center + Vector3.new(0, -17.2, 0), accent)

    local baseSize = 19.5 * platformScale
    local base = makePart(arenaFolder, "StartPlatform", Vector3.new(baseSize, 3, baseSize), center + Vector3.new(0, 5, 0), PALETTE.green, Enum.Material.SmoothPlastic)
    addNeonTrim(arenaFolder, "StartPlatformGlow", Vector3.new(baseSize + 0.2, 0.25, 0.3), base.Position + Vector3.new(0, 1.62, -(baseSize/2 + 0.05)), accent)
    generatedPlatforms[1] = {Part = base, Layer = 0, Lane = 0, TopY = base.Position.Y + base.Size.Y / 2}

    local currentLayerY = 5
    local platformPalette = {PALETTE.blue, PALETTE.purple, PALETTE.green, PALETTE.gold, PALETTE.cyan, PALETTE.pink}
    local formationCenter = Vector2.new(math.cos(rotationAngle), math.sin(rotationAngle)) * 13.3
    local formationPhase = rotationAngle
    local previousLayerRecords = {generatedPlatforms[1]}

    for layer = 1, layerCount do
        currentLayerY += rng:NextNumber(3.9, 4.2)
        local y = currentLayerY

        if layer > 1 then
            local driftAngle = rng:NextNumber(0, math.pi * 2)
            local driftDistance = rng:NextNumber(1.2, 1.6)
            formationCenter += Vector2.new(math.cos(driftAngle), math.sin(driftAngle)) * driftDistance
            formationPhase += rng:NextNumber(-0.35, 0.35)
        end

        local layerRecords = {}
        local padCount = math.max(3, laneCount + rng:NextInteger(-1, 1))
        for pad = 1, padCount do
            local angle = formationPhase + (pad - 1) * (math.pi * 2 / padCount) + rng:NextNumber(-0.15, 0.15)
            local radius = 8 + rng:NextNumber(0, 4) + (layer * 0.4)
            local x = formationCenter.X + math.cos(angle) * radius
            local z = formationCenter.Y + math.sin(angle) * radius
            local sizeMul = platformScale * rng:NextNumber(0.85, 1.15)
            local size = Vector3.new(rng:NextNumber(7, 11) * sizeMul, 2.2, rng:NextNumber(7, 11) * sizeMul)
            local color = platformPalette[((layer + pad) % #platformPalette) + 1]
            local part = makePart(arenaFolder, string.format("Pad_L%d_P%d", layer, pad), size, center + Vector3.new(x, y, z), color, Enum.Material.SmoothPlastic)
            local rotY = rng:NextNumber(0, math.pi * 2)
            part.CFrame = CFrame.new(part.Position) * CFrame.Angles(0, rotY, 0)
            addNeonTrim(arenaFolder, string.format("PadGlow_L%d_P%d", layer, pad), Vector3.new(size.X + 0.15, 0.2, 0.25), part.Position + Vector3.new(0, size.Y/2 + 0.1, 0), accent)
            local rec = {Part = part, Layer = layer, Lane = pad, TopY = part.Position.Y + part.Size.Y / 2, RotY = rotY}
            table.insert(generatedPlatforms, rec)
            table.insert(layerRecords, rec)
        end

        for _, rec in ipairs(layerRecords) do
            local reachable = false
            for _, prev in ipairs(previousLayerRecords) do
                local dx = rec.Part.Position.X - prev.Part.Position.X
                local dz = rec.Part.Position.Z - prev.Part.Position.Z
                local horiz = math.sqrt(dx * dx + dz * dz)
                local vert = rec.TopY - prev.TopY
                if horiz <= (Config.MAX_EDGE_GAP or 7.5) and vert > 0 and vert < 5.5 then
                    reachable = true
                    break
                end
            end
            if not reachable and #previousLayerRecords > 0 then
                local nearest = previousLayerRecords[1]
                local best = math.huge
                for _, prev in ipairs(previousLayerRecords) do
                    local dx = rec.Part.Position.X - prev.Part.Position.X
                    local dz = rec.Part.Position.Z - prev.Part.Position.Z
                    local d = math.sqrt(dx*dx + dz*dz)
                    if d < best then best = d; nearest = prev end
                end
                local target = nearest.Part.Position
                local cur = rec.Part.Position
                local dir = Vector3.new(target.X - cur.X, 0, target.Z - cur.Z)
                if dir.Magnitude > 0.1 then
                    local pull = math.min(dir.Magnitude * 0.45, 4.5)
                    rec.Part.Position = cur + dir.Unit * pull
                    rec.TopY = rec.Part.Position.Y + rec.Part.Size.Y / 2
                end
            end
        end
        previousLayerRecords = layerRecords
    end

    local finishY = currentLayerY + rng:NextNumber(3.8, 4.3)
    local finish = makePart(arenaFolder, "FinishPlatform", Vector3.new(16 * platformScale, 3, 16 * platformScale), center + Vector3.new(formationCenter.X, finishY, formationCenter.Y), PALETTE.gold, Enum.Material.Neon)
    generatedPlatforms[#generatedPlatforms + 1] = {Part = finish, Layer = layerCount + 1, Lane = 0, TopY = finish.Position.Y + finish.Size.Y / 2}
    addSign(arenaFolder, "FinishSign", "FINISH", finish.Position + Vector3.new(0, 6, 0), Vector3.new(12, 3, 1), PALETTE.cream)

    local hazardCount = math.max(1, (mod.HazardCount) or 2)
    for i = 1, hazardCount do
        local hY = 8 + rng:NextNumber(0, math.max(1, currentLayerY - 6))
        local hX = rng:NextNumber(-40, 40)
        local hZ = rng:NextNumber(-40, 40)
        local hazard = makePart(arenaFolder, "Hazard_" .. i, Vector3.new(4, 1.5, 4), center + Vector3.new(hX, hY, hZ), PALETTE.red, Enum.Material.Neon)
        hazard.CanCollide = false
        local light = Instance.new("PointLight")
        light.Color = PALETTE.red
        light.Range = 12
        light.Brightness = 2
        light.Parent = hazard
        task.spawn(function()
            while hazard.Parent do
                hazard.CFrame = hazard.CFrame * CFrame.Angles(0, math.rad(2), 0)
                task.wait(0.03)
            end
        end)
    end

    local lava = makePart(arenaFolder, "Lava", Vector3.new(200, 4, 200), center + Vector3.new(0, -8, 0), Color3.fromRGB(255, 80, 20), Enum.Material.Neon)
    lava.CanCollide = false
    local lavaLight = Instance.new("PointLight")
    lavaLight.Color = Color3.fromRGB(255, 100, 30)
    lavaLight.Range = 40
    lavaLight.Brightness = 3
    lavaLight.Parent = lava

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        atmosphere.Density = 0.16 + ((mod.FogBonus) or 0)
    end

    lava.Touched:Connect(function(hit)
        local character = hit.Parent
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local player = Players:GetPlayerFromCharacter(character)
        if not humanoid or humanoid.Health <= 0 then return end
        if player and secondChanceReady and secondChanceReady[player] then
            secondChanceReady[player] = false
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = CFrame.new(base.Position + Vector3.new(0, 6, 0))
                if playSound then playSound(Config.SOUND_WIN or 0, 0.6, root) end
                if sendState then sendState({ Phase = "Round", Message = player.Name .. " used Second Chance!" }) end
            end
            return
        end
        if player and alive and alive[player] then
            alive[player] = nil
            humanoid.Health = 0
            if countAlive then countAlive() end
        end
    end)

    ctx.currentMapName = currentMapName
    ctx.lastLayoutSignature = lastLayoutSignature
    return lava
end

	return { build = buildArena }
end

return Arena
