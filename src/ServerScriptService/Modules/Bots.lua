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
    task.spawn(function()
        local humanoid = bot.Humanoid
        local model = bot.Model
        local root = model:WaitForChild("HumanoidRootPart")

        local platformParts = {}
        for _, record in ipairs(ctx.generatedPlatforms) do
            table.insert(platformParts, record.Part)
        end
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Include
        rayParams.FilterDescendantsInstances = platformParts
        rayParams.IgnoreWater = true

        local function platformBelow()
            local result = workspace:Raycast(
                root.Position + Vector3.new(0, 1, 0),
                Vector3.new(0, -10, 0),
                rayParams
            )
            if not result then return nil end
            for _, record in ipairs(ctx.generatedPlatforms) do
                if result.Instance == record.Part then return record end
            end
            return nil
        end

        local function waitForLanding(target, timeout)
            local deadline = os.clock() + timeout
            local stableFrames = 0
            while os.clock() < deadline and humanoid.Health > 0 and ctx.alive[bot] and model.Parent do
                if platformBelow() == target and humanoid.FloorMaterial ~= Enum.Material.Air then
                    stableFrames += 1
                    if stableFrames >= 2 then return true end
                else
                    stableFrames = 0
                end
                task.wait(0.08)
            end
            return false
        end

        local function edgePoint(part, direction, inset)
            local localDirection = part.CFrame:VectorToObjectSpace(direction)
            local halfX = math.max(0.5, part.Size.X * 0.5 - inset)
            local halfZ = math.max(0.5, part.Size.Z * 0.5 - inset)
            local alongX = math.abs(localDirection.X) > 0.001 and halfX / math.abs(localDirection.X) or math.huge
            local alongZ = math.abs(localDirection.Z) > 0.001 and halfZ / math.abs(localDirection.Z) or math.huge
            local distance = math.min(alongX, alongZ)
            return part.Position + direction * math.max(0, distance)
        end

        local lastLayer = -1
        local lastProgressClock = os.clock()
        local stuckCount = 0
        humanoid.WalkSpeed = Config.BOT_WALK_SPEED or 16
        humanoid.UseJumpPower = true
        humanoid.JumpPower = Config.BOT_JUMP_POWER or Config.PLAYER_JUMP_POWER

        while ctx.roundActive and ctx.alive[bot] and model.Parent and humanoid.Health > 0 do
            local currentRecord = platformBelow()
            if not currentRecord then
                if os.clock() - lastProgressClock > (Config.BOT_STUCK_TIMEOUT or 6.5) then
                    local nearest, bestDist = nil, math.huge
                    local botRoot = model:FindFirstChild("HumanoidRootPart")
                    if botRoot then
                        for _, record in ipairs(ctx.generatedPlatforms) do
                            local d = (record.Part.Position - botRoot.Position).Magnitude
                            if d < bestDist then nearest, bestDist = record, d end
                        end
                    end
                    if nearest then
                        stuckCount += 1
                        local top = nearest.Part.Position + Vector3.new(0, nearest.Part.Size.Y / 2 + (Config.BOT_RECOVERY_TELEPORT_Y or 3.2), 0)
                        if stuckCount <= (Config.BOT_SOFT_RECOVERY_ATTEMPTS or 2) then
                            humanoid:MoveTo(top)
                        else
                            model:PivotTo(CFrame.new(top))
                        end
                        lastProgressClock = os.clock()
                    end
                end
                task.wait(0.12)
                continue
            end

            if currentRecord.Layer > lastLayer then
                lastLayer = currentRecord.Layer
                lastProgressClock = os.clock()
                stuckCount = 0
            elseif os.clock() - lastProgressClock > (Config.BOT_STUCK_TIMEOUT or 6.5) then
                stuckCount += 1
                local softLimit = Config.BOT_SOFT_RECOVERY_ATTEMPTS or 2
                local teleAfter = Config.BOT_TELEPORT_AFTER or 3
                local escalateAfter = Config.BOT_ESCALATE_AFTER or 5
                if stuckCount <= softLimit then
                    humanoid:MoveTo(currentRecord.Part.Position + Vector3.new(0, currentRecord.Part.Size.Y / 2 + 2.5, 0))
                elseif stuckCount <= teleAfter then
                    model:PivotTo(CFrame.new(currentRecord.Part.Position + Vector3.new(
                        (math.random() - 0.5) * 1.5,
                        currentRecord.Part.Size.Y / 2 + (Config.BOT_RECOVERY_TELEPORT_Y or 3.2),
                        (math.random() - 0.5) * 1.5
                    )))
                end
                lastProgressClock = os.clock()
                if stuckCount >= escalateAfter then
                    for _, record in ipairs(ctx.generatedPlatforms) do
                        if record.Layer == currentRecord.Layer + 1 then
                            model:PivotTo(CFrame.new(record.Part.Position + Vector3.new(0, record.Part.Size.Y / 2 + 3.5, 0)))
                            lastLayer = record.Layer
                            break
                        end
                    end
                    stuckCount = 0
                end
            end

            if humanoid.FloorMaterial == Enum.Material.Air then
                task.wait(0.1)
                continue
            end

            local options = {}
            for _, record in ipairs(ctx.generatedPlatforms) do
                if record.Layer == currentRecord.Layer + 1 then
                    local offset = record.Part.Position - currentRecord.Part.Position
                    local horizontal = Vector3.new(offset.X, 0, offset.Z).Magnitude
                    local edgeGap = horizontal
                        - math.min(currentRecord.Part.Size.X, currentRecord.Part.Size.Z) * 0.5
                        - math.min(record.Part.Size.X, record.Part.Size.Z) * 0.5
                    if edgeGap <= (Config.MAX_EDGE_GAP or 7.5) then
                        table.insert(options, {Record = record, Distance = edgeGap})
                    end
                end
            end

            table.sort(options, function(a, b)
                return a.Distance < b.Distance
            end)

            if #options == 0 then
                task.wait(0.2)
                continue
            end

            local pickIndex = 1
            if #options >= 2 and math.random() < (Config.BOT_TARGET_RANDOMNESS or 0.35) then
                pickIndex = math.random(1, math.min(3, #options))
            end
            local target = options[pickIndex].Record
            local offset = target.Part.Position - currentRecord.Part.Position
            local flatOffset = Vector3.new(offset.X, 0, offset.Z)
            if flatOffset.Magnitude < 0.01 then
                task.wait(0.15)
                continue
            end

            local direction = flatOffset.Unit
            local launchPoint = edgePoint(currentRecord.Part, direction, 0.3)
            local launchPosition = Vector3.new(launchPoint.X, currentRecord.TopY + 3, launchPoint.Z)
            local landingPoint = edgePoint(target.Part, -direction, 0.3)
            local landingPosition = Vector3.new(landingPoint.X, target.TopY + 3, landingPoint.Z)

            humanoid:MoveTo(launchPosition)
            local approachDeadline = os.clock() + 3
            local reachedLaunch = false
            while os.clock() < approachDeadline and humanoid.Health > 0 and ctx.alive[bot] do
                local delta = Vector3.new(root.Position.X - launchPosition.X, 0, root.Position.Z - launchPosition.Z)
                if delta.Magnitude <= 0.55 then
                    reachedLaunch = true
                    break
                end
                if platformBelow() ~= currentRecord then break end
                task.wait(0.08)
            end

            if reachedLaunch and humanoid.Health > 0 and ctx.alive[bot]
                and platformBelow() == currentRecord
                and humanoid.FloorMaterial ~= Enum.Material.Air then

                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.05)
                humanoid:MoveTo(landingPosition)

                if not waitForLanding(target, 3.5) then
                    local recovery = Vector3.new(
                        currentRecord.Part.Position.X,
                        currentRecord.TopY + 3,
                        currentRecord.Part.Position.Z
                    )
                    humanoid:MoveTo(recovery)
                    local recoveryDeadline = os.clock() + 2
                    while os.clock() < recoveryDeadline and humanoid.Health > 0 and ctx.alive[bot] do
                        if platformBelow() == currentRecord and humanoid.FloorMaterial ~= Enum.Material.Air then
                            break
                        end
                        task.wait(0.08)
                    end
                end
            else
                humanoid:MoveTo(Vector3.new(
                    currentRecord.Part.Position.X,
                    currentRecord.TopY + 3,
                    currentRecord.Part.Position.Z
                ))
                task.wait(0.25)
            end
            task.wait(0.12)
        end
    end)
end


	return { createBot = createBot, runBotAI = runBotAI }
end

return Bots
