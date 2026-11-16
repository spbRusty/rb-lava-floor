local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local roundState = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "FloorIsLavaHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "StatusPanel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.fromScale(0.5, 0.035)
panel.Size = UDim2.fromOffset(360, 92)
panel.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -24, 0, 34)
title.Font = Enum.Font.GothamBold
title.Text = "FLOOR IS LAVA"
title.TextColor3 = Color3.fromRGB(255, 115, 55)
title.TextScaled = true
title.Parent = panel

local message = Instance.new("TextLabel")
message.Name = "Message"
message.BackgroundTransparency = 1
message.Position = UDim2.fromOffset(12, 43)
message.Size = UDim2.new(1, -24, 0, 22)
message.Font = Enum.Font.GothamMedium
message.Text = "Подключение..."
message.TextColor3 = Color3.fromRGB(245, 245, 245)
message.TextScaled = true
message.Parent = panel

local timer = Instance.new("TextLabel")
timer.Name = "Timer"
timer.BackgroundTransparency = 1
timer.AnchorPoint = Vector2.new(1, 0)
timer.Position = UDim2.new(1, -12, 0, 8)
timer.Size = UDim2.fromOffset(54, 24)
timer.Font = Enum.Font.GothamBold
timer.Text = ""
timer.TextColor3 = Color3.fromRGB(255, 220, 120)
timer.TextScaled = true
timer.Parent = panel

roundState.OnClientEvent:Connect(function(state)
    message.Text = state.Message or ""
    timer.Text = state.TimeLeft and state.TimeLeft > 0 and tostring(state.TimeLeft) or ""
end)