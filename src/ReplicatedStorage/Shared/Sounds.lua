--[[
	Shared sound helper. Asset IDs come from Config (0 = disabled).
]]
local SoundService = game:GetService("SoundService")

local Sounds = {}

function Sounds.play(assetId, volume, parent)
	assetId = tonumber(assetId) or 0
	if assetId <= 0 then
		return nil
	end

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(assetId)
	sound.Volume = volume or 0.55
	sound.Parent = parent or SoundService
	sound:Play()

	sound.Ended:Connect(function()
		if sound.Parent then
			sound:Destroy()
		end
	end)

	task.delay(10, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)

	return sound
end

return Sounds
