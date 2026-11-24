--[[
	Plays jump SFX when the local player jumps (Config.SOUND_JUMP).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))

local function bindCharacter(character)
	local humanoid = character:WaitForChild("Humanoid", 8)
	if not humanoid then
		return
	end

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			local root = character:FindFirstChild("HumanoidRootPart")
			Sounds.play(Config.SOUND_JUMP, 0.45, root)
		end
	end)
end

if player.Character then
	task.spawn(bindCharacter, player.Character)
end
player.CharacterAdded:Connect(bindCharacter)
