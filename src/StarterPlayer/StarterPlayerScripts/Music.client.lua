local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local roundState = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local assetId = tonumber(Config.MUSIC_ASSET_ID) or 0
if assetId <= 0 then
    warn("[FloorIsLava] Background music is disabled: upload the soundtrack and set Config.MUSIC_ASSET_ID.")
    return
end

local music = Instance.new("Sound")
music.Name = "FloorIsLavaBackgroundMusic"
music.SoundId = "rbxassetid://" .. tostring(assetId)
music.Looped = true
music.Volume = 0
music.PlaybackSpeed = 1
music.Parent = SoundService
music:Play()

local activeTween
local function setMusic(volume, speed)
    if activeTween then activeTween:Cancel() end
    activeTween = TweenService:Create(
        music,
        TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { Volume = volume, PlaybackSpeed = speed }
    )
    activeTween:Play()
end

roundState.OnClientEvent:Connect(function(state)
    local phase = state.Phase or "Waiting"
    local timeLeft = tonumber(state.TimeLeft) or 0

    if phase == "Round" then
        if timeLeft > 0 and timeLeft <= 25 then
            setMusic(0.42, 1.1)
        else
            setMusic(0.34, 1.04)
        end
    elseif phase == "Intermission" or phase == "Waiting" then
        setMusic(0.25, 0.96)
    else
        setMusic(0, 1)
    end
end)
