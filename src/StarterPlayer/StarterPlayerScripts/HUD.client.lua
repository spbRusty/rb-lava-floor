local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local roundState = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local COLORS = {
    panel = Color3.fromRGB(18, 24, 38),
    panelLight = Color3.fromRGB(31, 41, 61),
    white = Color3.fromRGB(246, 248, 255),
    muted = Color3.fromRGB(160, 174, 198),
    orange = Color3.fromRGB(255, 112, 54),
    gold = Color3.fromRGB(255, 207, 100),
    cyan = Color3.fromRGB(92, 218, 239),
    green = Color3.fromRGB(91, 225, 157),
    red = Color3.fromRGB(255, 82, 82),
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local gui = create("ScreenGui", {
    Name = "FloorIsLavaHUD",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 20,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local scale = create("UIScale", { Scale = 1 }, gui)
local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local width = camera.ViewportSize.X
    scale.Scale = math.clamp(width / 1280, 0.72, 1)
end
updateScale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale)
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- Top status card
local top = create("Frame", {
    Name = "MatchPanel",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 22),
    Size = UDim2.fromOffset(430, 112),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 0.06,
    BorderSizePixel = 0,
}, gui)
corner(top, 18)
stroke(top, Color3.fromRGB(91, 111, 145), 0.55, 1)

local topGradient = create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(31, 42, 63)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 21, 34)),
    }),
    Rotation = 90,
}, top)

create("TextLabel", {
    Name = "Eyebrow",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 10),
    Size = UDim2.new(1, -36, 0, 18),
    Font = Enum.Font.GothamBold,
    Text = "SURVIVAL ROUND",
    TextColor3 = COLORS.orange,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTransparency = 0.05,
}, top)

local phaseLabel = create("TextLabel", {
    Name = "Phase",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 30),
    Size = UDim2.new(1, -36, 0, 34),
    Font = Enum.Font.GothamBlack,
    Text = "FLOOR IS LAVA",
    TextColor3 = COLORS.white,
    TextSize = 25,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, top)

local timerPill = create("Frame", {
    Name = "TimerPill",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -14, 0, 25),
    Size = UDim2.fromOffset(86, 43),
    BackgroundColor3 = Color3.fromRGB(75, 40, 32),
    BorderSizePixel = 0,
}, top)
corner(timerPill, 12)
local timerLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Font = Enum.Font.GothamBlack,
    Text = "--:--",
    TextColor3 = COLORS.gold,
    TextSize = 21,
}, timerPill)

local subtitle = create("TextLabel", {
    Name = "Subtitle",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 70),
    Size = UDim2.new(1, -36, 0, 24),
    Font = Enum.Font.GothamMedium,
    Text = "Waiting for players...",
    TextColor3 = COLORS.muted,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, top)

-- Left-side stat chips
local stats = create("Frame", {
    Name = "Stats",
    Position = UDim2.new(0, 22, 0, 22),
    Size = UDim2.fromOffset(164, 94),
    BackgroundTransparency = 1,
}, gui)

local function makeStat(name, y, label, value, accent)
    local card = create("Frame", {
        Name = name,
        Position = UDim2.fromOffset(0, y),
        Size = UDim2.fromOffset(164, 42),
        BackgroundColor3 = COLORS.panel,
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
    }, stats)
    corner(card, 12)
    stroke(card, accent, 0.65, 1)
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 5),
        Size = UDim2.fromOffset(64, 30),
        Font = Enum.Font.GothamBold,
        Text = label,
        TextColor3 = COLORS.muted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)
    local valueLabel = create("TextLabel", {
        Name = "Value",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(72, 30),
        Font = Enum.Font.GothamBlack,
        Text = "0",
        TextColor3 = accent,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, card)
    return valueLabel
end

local coinsValue = makeStat("Coins", 0, "COINS", "0", COLORS.gold)
local winsValue = makeStat("Wins", 50, "WINS", "0", COLORS.cyan)

local function bindStats()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    local coins = leaderstats:FindFirstChild("Coins")
    local wins = leaderstats:FindFirstChild("Wins")
    if coins then
        coinsValue.Text = tostring(coins.Value)
        coins:GetPropertyChangedSignal("Value"):Connect(function()
            coinsValue.Text = tostring(coins.Value)
        end)
    end
    if wins then
        winsValue.Text = tostring(wins.Value)
        wins:GetPropertyChangedSignal("Value"):Connect(function()
            winsValue.Text = tostring(wins.Value)
        end)
    end
end
player.ChildAdded:Connect(function(child)
    if child.Name == "leaderstats" then task.defer(bindStats) end
end)
task.defer(bindStats)

-- Alive counter, right side
local aliveCard = create("Frame", {
    Name = "AliveCard",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -22, 0, 22),
    Size = UDim2.fromOffset(142, 58),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 0.06,
    BorderSizePixel = 0,
}, gui)
corner(aliveCard, 14)
stroke(aliveCard, COLORS.green, 0.65, 1)
create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(12, 7),
    Size = UDim2.fromOffset(118, 16),
    Font = Enum.Font.GothamBold,
    Text = "SURVIVORS",
    TextColor3 = COLORS.muted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, aliveCard)
local function updateMobileLayout()
    local camera = workspace.CurrentCamera
    if not camera then return end
    if camera.ViewportSize.X < 760 then
        stats.Position = UDim2.new(0, 12, 0, 138)
        aliveCard.Position = UDim2.new(1, -12, 0, 138)
    else
        stats.Position = UDim2.new(0, 22, 0, 22)
        aliveCard.Position = UDim2.new(1, -22, 0, 22)
    end
end
updateMobileLayout()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateMobileLayout)
end

local aliveLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(12, 21),
    Size = UDim2.fromOffset(118, 29),
    Font = Enum.Font.GothamBlack,
    Text = "--",
    TextColor3 = COLORS.green,
    TextSize = 22,
    TextXAlignment = Enum.TextXAlignment.Left,
}, aliveCard)

-- Current arena badge
local mapBadge = create("Frame", {
    Name = "MapBadge",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 142),
    Size = UDim2.fromOffset(210, 30),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
}, gui)
corner(mapBadge, 10)
stroke(mapBadge, COLORS.cyan, 0.72, 1)
local mapLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Font = Enum.Font.GothamBold,
    Text = "ARENA  •  WAITING",
    TextColor3 = COLORS.cyan,
    TextSize = 11,
}, mapBadge)

-- Round result card
local resultCard = create("Frame", {
    Name = "RoundResult",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.48),
    Size = UDim2.fromOffset(470, 176),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 10,
}, gui)
corner(resultCard, 22)
stroke(resultCard, COLORS.gold, 0.25, 2)
create("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(39, 48, 68), Color3.fromRGB(17, 22, 35)),
    Rotation = 90,
}, resultCard)
local resultScale = create("UIScale", { Scale = 0.82 }, resultCard)
local resultEyebrow = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(22, 18),
    Size = UDim2.new(1, -44, 0, 20),
    Font = Enum.Font.GothamBold,
    Text = "ROUND COMPLETE",
    TextColor3 = COLORS.orange,
    TextSize = 12,
    ZIndex = 11,
}, resultCard)
local resultTitle = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(22, 48),
    Size = UDim2.new(1, -44, 0, 54),
    Font = Enum.Font.GothamBlack,
    Text = "VICTORY!",
    TextColor3 = COLORS.gold,
    TextSize = 34,
    TextWrapped = true,
    ZIndex = 11,
}, resultCard)
local resultSubtitle = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(22, 112),
    Size = UDim2.new(1, -44, 0, 34),
    Font = Enum.Font.GothamMedium,
    Text = "You survived the rising lava.",
    TextColor3 = COLORS.muted,
    TextSize = 15,
    TextWrapped = true,
    ZIndex = 11,
}, resultCard)

local resultToken = 0
local function showResult(won, message)
    resultToken += 1
    local token = resultToken
    resultCard.Visible = true
    resultEyebrow.Text = won and "LAST PLAYER STANDING" or "ROUND COMPLETE"
    resultTitle.Text = won and "VICTORY!" or "SURVIVAL REPORT"
    resultTitle.TextColor3 = won and COLORS.gold or COLORS.orange
    resultSubtitle.Text = message
    resultScale.Scale = 0.82
    resultCard.BackgroundTransparency = 0.3
    TweenService:Create(resultScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = 1,
    }):Play()
    TweenService:Create(resultCard, TweenInfo.new(0.25), {
        BackgroundTransparency = 0.04,
    }):Play()
    task.delay(4.2, function()
        if token ~= resultToken then return end
        local fade = TweenService:Create(resultCard, TweenInfo.new(0.25), {
            BackgroundTransparency = 1,
        })
        fade:Play()
        TweenService:Create(resultScale, TweenInfo.new(0.25), { Scale = 0.94 }):Play()
        task.wait(0.28)
        if token == resultToken then resultCard.Visible = false end
    end)
end

-- Bottom toast
local toast = create("Frame", {
    Name = "Toast",
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -34),
    Size = UDim2.fromOffset(360, 54),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
}, gui)
corner(toast, 14)
stroke(toast, COLORS.orange, 0.35, 1)
local toastText = create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -24, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    Font = Enum.Font.GothamBold,
    Text = "",
    TextColor3 = COLORS.white,
    TextSize = 16,
    TextTransparency = 1,
    TextWrapped = true,
}, toast)

local toastToken = 0
local function showToast(text, color)
    toastToken += 1
    local token = toastToken
    toast.Visible = true
    toastText.Text = text
    toastText.TextColor3 = color or COLORS.white
    toast.BackgroundTransparency = 1
    toastText.TextTransparency = 1
    TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.05,
    }):Play()
    TweenService:Create(toastText, TweenInfo.new(0.22), { TextTransparency = 0 }):Play()
    task.delay(3, function()
        if token ~= toastToken then return end
        TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(toastText, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        task.wait(0.28)
        if token == toastToken then toast.Visible = false end
    end)
end

local previousPhase = ""
roundState.OnClientEvent:Connect(function(state)
    local phase = state.Phase or "Waiting"
    local message = state.Message or ""
    local timeLeft = tonumber(state.TimeLeft) or 0
    phaseLabel.Text = phase == "Round" and "SURVIVE!" or phase == "Winner" and "VICTORY!" or phase == "Finished" and "ROUND OVER" or phase == "Intermission" and "GET READY" or "FLOOR IS LAVA"
    subtitle.Text = message
    timerLabel.Text = timeLeft > 0 and string.format("%02d:%02d", math.floor(timeLeft / 60), timeLeft % 60) or "--:--"
    aliveLabel.Text = tostring(state.Alive or 0)
    mapLabel.Text = "ARENA  •  " .. string.upper(state.Map or "UNKNOWN")
    timerPill.BackgroundColor3 = phase == "Round" and Color3.fromRGB(83, 39, 29) or Color3.fromRGB(43, 53, 73)

    if phase == "Winner" then
        showToast(message, COLORS.gold)
        showResult(true, message)
    elseif phase == "Finished" then
        showToast(message, COLORS.orange)
        showResult(false, message)
    elseif phase == "Round" and previousPhase ~= "Round" then
        showToast("The lava is rising. Keep moving!", COLORS.orange)
    elseif phase == "Intermission" and previousPhase ~= "Intermission" then
        showToast("Next round is coming. Get ready!", COLORS.cyan)
    end
    previousPhase = phase
end)

-- Subtle timer pulse when the round is active
local pulseTime = 0
RunService.RenderStepped:Connect(function(dt)
    pulseTime += dt
    if timerPill.BackgroundColor3 == Color3.fromRGB(83, 39, 29) then
        timerPill.BackgroundTransparency = 0.04 + (math.sin(pulseTime * 3) + 1) * 0.035
    else
        timerPill.BackgroundTransparency = 0
    end
end)
