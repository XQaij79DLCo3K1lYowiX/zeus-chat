local debug = true
local function log(message)
	if debug and game["Run Service"]:IsStudio() then
		print("[autocomp server] " .. message)
	end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local mod = _G.datastoreModule

local waits = 0
while not mod do
	if waits > 10 then
		error("Waiting for mod timeout")
		return
	end
	waits += 1
	wait(0.4)
	mod = _G.datastoreModule
end


local DataStore = require(mod)
local store = DataStore.new("words")


local GetWordStats = _G.autoCompFetch
local WordCache: {[Player]: {[string]: number}} = {}


local AUTOSAVE_INTERVAL = 120

-- ==========================
-- UTILITY
-- ==========================

local function NormalizeWord(word: string)
	-- make it normal and not stupid and weird
	return string.lower(word:gsub("[%p%c]", ""))
end

local function SplitWords(message: string)
	local words = {}
	for word in string.gmatch(message, "%S+") do
		local w = NormalizeWord(word)
		if w ~= "" then
			table.insert(words, w)
		end
	end
	return words
end


local function stringStartsWith(prefix, inputString)
	if #prefix > #inputString then
		return false
	end
	return string.sub(inputString, 1, #prefix) == prefix
end

-- ==========================
-- LOAD / SAVE
-- ==========================

local function LoadStats(player: Player)
	log("Loading stats...")
	local key = "WordStats_" .. player.UserId
	local stored = store:Get(key)

	if typeof(stored) == "table" then
		WordCache[player] = stored
	else
		WordCache[player] = {}
	end
	log("finished loading")
end

local function SaveStats(player: Player)
	--log("saving stats...")
	local data = WordCache[player]
	if not data then return end

	local key = "WordStats_" .. player.UserId
	store:Set(key, data)
	--log("finished saving")
end

-- ==========================
-- MAIN MESSAGE HANDLER
-- ==========================

local function RegisterWords(player: Player, message: string)
	--log("registering words...")
	local data = WordCache[player]
	if not data then return end

	local words = SplitWords(message)

	for _, word in ipairs(words) do
		data[word] = (data[word] or 0) + 1
	end
	--log("finished registering")
end

-- ==========================
-- REMOTE FUNCTION FOR CLIENT
-- ==========================

GetWordStats.OnServerInvoke = function(player)
	return WordCache[player] or {}
end

-- ==========================
-- PLAYER HANDLERS
-- ==========================

Players.PlayerAdded:Connect(function(player)
	LoadStats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	SaveStats(player)
	WordCache[player] = nil
end)

-- ==========================
-- AUTOSAVE LOOP
-- ==========================

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for player, _ in pairs(WordCache) do
			SaveStats(player)
		end
	end
end)

-- ==========================
-- HOOK INTO THE CHAT SYSTEM
-- ==========================

local brod = _G.brodcastRemote
brod.OnServerEvent:Connect(function(player, message)
	if stringStartsWith(";", message) then
		return
	end
	RegisterWords(player, message)
end)