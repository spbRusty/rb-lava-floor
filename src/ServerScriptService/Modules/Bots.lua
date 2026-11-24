--[[ Bot creation and AI - extracted from GameServer ]]
local Bots = {}

function Bots.create(ctx)
	local Config = ctx.Config
	local PALETTE = ctx.PALETTE

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

    local function addBotArmor(name, size, offset, color, material, shape)
        local armor = Instance.new("Part")
        armor.Name = name
        armor.Size = size
        armor.Shape = shape or Enum.PartType.Block
        armor.Color = color
        armor.Material = material or Enum.Material.SmoothPlastic
        armor.CanCollide = false
        armor.CanTouch = false
        armor.CanQuery = false
        armor.Massless = true
        armor.Anchored = false
        armor.CFrame = root.CFrame * CFrame.new(offset)
        armor.Parent = model
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = armor
        weld.Parent = armor
        return armor
    end

    local trimColor = index % 2 == 0 and Color3.fromRGB(65, 235, 255) or Color3.fromRGB(255, 190, 55)
    addBotArmor("ChestArmor", Vector3.new(1.55, 1.15, 0.18), Vector3.new(0, 0.05, -0.58), trimColor, Enum.Material.Metal)
    addBotArmor("Helmet", Vector3.new(1.85, 0.72, 1.25), Vector3.new(0, 2.08, 0), bodyColor, Enum.Material.Metal, Enum.PartType.Ball)
    addBotArmor("Visor", Vector3.new(1.35, 0.32, 0.16), Vector3.new(0, 1.88, -0.61), Color3.fromRGB(24, 34, 52), Enum.Material.Neon)
    addBotArmor("LeftShoulder", Vector3.new(0.72, 0.72, 0.82), Vector3.new(-1.35, 0.72, 0), trimColor, Enum.Material.Metal, Enum.PartType.Ball)
    addBotArmor("RightShoulder", Vector3.new(0.72, 0.72, 0.82), Vector3.new(1.35, 0.72, 0), trimColor, Enum.Material.Metal, Enum.PartType.Ball)
    addBotArmor("Jetpack", Vector3.new(1.25, 1.25, 0.55), Vector3.new(0, 0.15, 0.82), Color3.fromRGB(45, 55, 76), Enum.Material.Metal)
    addBotArmor("JetpackCore", Vector3.new(0.55, 0.7, 0.18), Vector3.new(0, 0.15, 1.13), trimColor, Enum.Material.Neon)

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
    humanoid.WalkSpeed = 16
    humanoid.UseJumpPower = true
    humanoid.JumpPower = Config.PLAYER_JUMP_POWER + 3
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.Parent = model

    model.PrimaryPart = root
    model.Parent = ctx.botFolder
    model:PivotTo(CFrame.new(spawnPosition))
    pcall(function() root:SetNetworkOwner(nil) end)
    local record = {IsBot = true, Model = model, Humanoid = humanoid, Name = "BOT " .. index}
    ctx.botByModel[model] = record
    return record
end

local function runBotAI(bot)
    local model = bot.Model
    local humanoid = bot.Humanoid
    local root = model and model.PrimaryPart
    if not model or not humanoid or not root or humanoid.Health <= 0 then return end

    local platforms = ctx.generatedPlatforms
    if not platforms or #platforms < 2 then return end

    local targetIndex = bot.targetIndex or 2
    local stuckFrames = bot.stuckFrames or 0
    local lastPos = bot.lastPos or root.Position

    local function platformBelow(pos)
        local origin = pos + Vector3.new(0, 2, 0)
        local dir = Vector3.new(0, -12, 0)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {model, ctx.botFolder}
        local result = workspace:Raycast(origin, dir, params)
        if result and result.Instance then
            for i, rec in ipairs(platforms) do
                if rec.Part == result.Instance or result.Instance:IsDescendantOf(rec.Part) then
                    return i, rec
                end
            end
        end
        return nil, nil
    end

    local belowIdx = platformBelow(root.Position)
    if belowIdx and belowIdx >= targetIndex then
        targetIndex = math.min(belowIdx + 1, #platforms)
    end

    local target = platforms[targetIndex]
    if not target or not target.Part or not target.Part.Parent then
        targetIndex = math.min(targetIndex + 1, #platforms)
        target = platforms[targetIndex]
        if not target then return end
    end

    local targetPos = target.Part.Position + Vector3.new(0, target.Part.Size.Y / 2 + 2, 0)
    local edgePoint = targetPos
    if target.RotY then
        local half = math.min(target.Part.Size.X, target.Part.Size.Z) * 0.35
        local offset = CFrame.Angles(0, target.RotY, 0) * Vector3.new(0, 0, -half)
        edgePoint = target.Part.Position + Vector3.new(offset.X, target.Part.Size.Y / 2 + 1.5, offset.Z)
    end

    local toTarget = edgePoint - root.Position
    local horiz = Vector3.new(toTarget.X, 0, toTarget.Z)
    local dist = horiz.Magnitude

    if (root.Position - lastPos).Magnitude < 0.4 then
        stuckFrames += 1
    else
        stuckFrames = 0
    end
    bot.lastPos = root.Position
    bot.stuckFrames = stuckFrames

    if stuckFrames > 40 then
        humanoid.Jump = true
        if stuckFrames > 80 then
            targetIndex = math.min(targetIndex + 1, #platforms)
            stuckFrames = 0
        end
        bot.targetIndex = targetIndex
        return
    end

    if dist > 1.2 then
        humanoid:MoveTo(edgePoint)
    end

    local maxGap = Config.MAX_EDGE_GAP or 7.5
    local jumpMargin = Config.BOT_JUMP_MARGIN or 1.2
    if dist < maxGap + jumpMargin and toTarget.Y > -1 and humanoid.FloorMaterial ~= Enum.Material.Air then
        if dist > 2.5 or toTarget.Y > 1.5 then
            humanoid.Jump = true
        end
    end

    bot.targetIndex = targetIndex
end

	return { createBot = createBot, runBotAI = runBotAI }
end

return Bots
