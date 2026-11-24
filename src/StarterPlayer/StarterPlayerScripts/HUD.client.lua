local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Temporary restore: full shop HUD is in branch artifacts; this unbreaks PLACEHOLDER.
-- Pull the full HUD.client.lua from the PR notes / local sandbox when ready.

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundState = remotes:WaitForChild("RoundState")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local COLORS = {
	panel = Color3.fromRGB(38, 64, 108),
	white = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(207, 222, 247),
	orange = Color3.fromRGB(255, 132, 48),
	gold = Color3.fromRGB(255, 220, 72),
	cyan = Color3.fromRGB(73, 225, 245),
	green = Color3.fromRGB(117, 235, 100),
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

local gui = create("ScreenGui", {
	Name = "FloorIsLavaHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 20,
}, playerGui)

local top = create("Frame", {
	Name = "MatchPanel",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 22),
	Size = UDim2.fromOffset(430, 100),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
}, gui)
corner(top, 18)

local phaseLabel = create("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(18, 16),
	Size = UDim2.new(1, -36, 0, 36),
	Font = Enum.Font.GothamBlack,
	Text = "FLOOR IS LAVA",
	TextColor3 = COLORS.white,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
}, top)

local subtitle = create("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(18, 56),
	Size = UDim2.new(1, -36, 0, 28),
	Font = Enum.Font.GothamMedium,
	Text = "Waiting...",
	TextColor3 = COLORS.muted,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
}, top)

local timerLabel = create("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 20),
	Size = UDim2.fromOffset(90, 40),
	Font = Enum.Font.GothamBlack,
	Text = "--:--",
	TextColor3 = COLORS.gold,
	TextSize = 22,
}, top)

local modLabel = create("TextLabel", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 130),
	Size = UDim2.fromOffset(320, 24),
	Font = Enum.Font.GothamBold,
	Text = "MOD  •  —",
	TextColor3 = COLORS.orange,
	TextSize = 12,
}, gui)

roundState.OnClientEvent:Connect(function(state)
	local phase = state.Phase or "Waiting"
	local message = state.Message or ""
	local timeLeft = tonumber(state.TimeLeft) or 0
	phaseLabel.Text = phase == "Round" and "SURVIVE!" or phase == "Winner" and "VICTORY!" or phase == "Finished" and "ROUND OVER" or phase == "Intermission" and "GET READY" or "FLOOR IS LAVA"
	subtitle.Text = message
	timerLabel.Text = timeLeft > 0 and string.format("%02d:%02d", math.floor(timeLeft / 60), timeLeft % 60) or "--:--"
	if state.Modifier and state.Modifier ~= "" then
		modLabel.Text = "MOD  •  " .. string.upper(state.Modifier)
	end
end)

-- Shop: lightweight purchase UI
local shopPurchase = remotes:WaitForChild("ShopPurchase")
local shopCatalog = remotes:WaitForChild("ShopCatalog")

local shopBtn = create("TextButton", {
	Name = "ShopButton",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 22, 1, -24),
	Size = UDim2.fromOffset(120, 46),
	BackgroundColor3 = Color3.fromRGB(48, 90, 140),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBlack,
	Text = "SHOP",
	TextColor3 = COLORS.white,
	TextSize = 16,
}, gui)
corner(shopBtn, 14)

local shopOpen = false
local shopFrame = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(300, 260),
	BackgroundColor3 = COLORS.panel,
	Visible = false,
	ZIndex = 20,
}, gui)
corner(shopFrame, 16)

local shopList = create("Frame", {
	Position = UDim2.fromOffset(12, 40),
	Size = UDim2.new(1, -24, 1, -52),
	BackgroundTransparency = 1,
	ZIndex = 21,
}, shopFrame)
create("UIListLayout", { Padding = UDim.new(0, 6) }, shopList)

create("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(12, 8),
	Size = UDim2.new(1, -24, 0, 28),
	Font = Enum.Font.GothamBlack,
	Text = "SHOP",
	TextColor3 = COLORS.gold,
	TextSize = 18,
	ZIndex = 21,
}, shopFrame)

local function refreshShop()
	for _, child in ipairs(shopList:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local ok, result = pcall(function()
		local catalog, owned = shopCatalog:InvokeServer()
		return { catalog = catalog, owned = owned or {} }
	end)
	if not ok or type(result) ~= "table" then return end
	local catalog, owned = result.catalog, result.owned or {}
	if type(catalog) ~= "table" then return end
	for _, item in ipairs(catalog) do
		local btn = create("TextButton", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = owned[item.Id] and Color3.fromRGB(50, 90, 60) or Color3.fromRGB(150, 100, 30),
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Text = owned[item.Id] and (item.Name .. " — OWNED") or (item.Name .. " — " .. tostring(item.Price) .. "c"),
			TextColor3 = COLORS.white,
			TextSize = 13,
			ZIndex = 22,
		}, shopList)
		corner(btn, 8)
		if not owned[item.Id] then
			btn.Activated:Connect(function()
				local success = shopPurchase:InvokeServer(item.Id)
				if success then refreshShop() end
			end)
		end
	end
end

shopBtn.Activated:Connect(function()
	shopOpen = not shopOpen
	shopFrame.Visible = shopOpen
	if shopOpen then refreshShop() end
end)
