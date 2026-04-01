-- used for somthing, i forget what

wait(1)
local chatted = _G.chatted
local usersfolder = _G.usersFolder
local Players = game:GetService("Players")



Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		chatted:Fire(message, player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	player.Chatted:Connect(function(message)
		chatted:Fire(message, player)
	end)
end

