-- handles ALL of the gui and some client side stuff.
-- visuals, quality of life shit, etc.

local brod = _G.brodcastRemote
local rec = _G.receiveRemote
local Service = game:GetService("TextChatService")
local emoji = _G.emojiModule
local conf = _G.config
local cmds = {}


local waits = 0          -- this wait / timeout thing CANNOT be efficient. whatevre.
while not emoji do
	if waits > 10 then
		error("timeout")
		return
	end
	waits += 1
	wait(0.4)
	emoji = _G.emojiModule
end


local emojis = require(emoji)

local waits = 0
while not conf do
	if waits > 10 then
		error("timeout")
		return
	end
	waits += 1
	wait(0.4)
	conf = _G.config
end

local config = require(conf)


local waits = 0
while not brod do
	if waits > 10 then
		error("timeout")
		return
	end
	waits += 1
	wait(0.4)
	brod = _G.brodcastRemote
end

if _G.fetchCmds and config.adonisAutoComplete then
	print("adonis present")
	cmds = _G.fetchCmds:InvokeServer()
end


local debug = false

local function log(message)
	if debug then
		print("[CLIENT - CHAT] " .. message)
	end
end


local function check(targetString)

	for key, value in pairs(config.users) do
		if type(key) == "number" then
			-- array-like entry
			if value == targetString then
				return value  -- return the username string
			end
		else
			-- dictionary-like entry
			if key == targetString then
				return value  -- return the table with user data
			end
		end
	end
	
	if config.whitelist == false then
		return targetString
	end

	return false
end

----------------------------------------------------------------
-- AUTOCOMPLETE ENGINE (scary)

--[[
This shit was so annoying to make, though
it was a lot of fun. This feature singlehandly
makes this one of the best if not the best
implimented custom chat bar on the platform.
]]

----------------------------------------------------------------

-- providers, allow autocompleate sugguestions to come from multiple sources
local AutoCompleteProviders = {}

-- active autocompleate state
local activeProvider = nil
local activeMatch = nil

----------------------------------------------------------------
-- UTILITY: replace a specific character range in a string
----------------------------------------------------------------
local function replaceRange(text, startPos, endPos, replacement)
	return text:sub(1, startPos - 1)
		.. replacement
		.. text:sub(endPos + 1)
end

----------------------------------------------------------------
-- Utility: extract trailing non-space token
----------------------------------------------------------------
local function getLastWord(text)
	text = text:match("^(.-)%s*$")
	return text:match("(%S+)$") or ""
end

----------------------------------------------------------------
-- Utility: build ghost autocomplete text, provider aware
----------------------------------------------------------------
local function buildAutoText(text, suggestion)
	if not suggestion then
		return "  > "
	end

	-- check if provider is active and if so use the prvfix length
	if activeMatch and activeMatch.prefix then
		local remaining = suggestion:sub(#activeMatch.prefix + 1)
		return "  > "
			.. string.rep(" ", #text)
			.. remaining
	end

	-- just in case, bettwer safe then sorry
	local lastWord = getLastWord(text)
	local remaining = suggestion:sub(#lastWord + 1)

	return "  > "
		.. string.rep(" ", #text)
		.. remaining
end


----------------------------------------------------------------
-- PROVIDER: common words, uses a datastore and has server side logic too
----------------------------------------------------------------
table.insert(AutoCompleteProviders, {
	Name = "WordStats",

	-- detecs a normal trailing word
	Match = function(text)
		local trimmed = text:match("^(.-)%s*$")
		local lastWord = trimmed:match("(%S+)$")
		if not lastWord then return nil end

		return {
			prefix = lastWord,
			startPos = #trimmed - #lastWord + 1,
			endPos = #trimmed
		}
	end,

	-- suggests the one with the highest frequency
	Suggest = function(match, stats)
		if match.prefix == "" then return nil end
		local prefix = match.prefix:lower()

		local bestWord = nil
		local bestScore = -1

		for word, score in pairs(stats) do
			if word:sub(1, #prefix):lower() == prefix then
				if score > bestScore then
					bestScore = score
					bestWord = word
				end
			end
		end

		if bestScore == 1 then
			return nil
		end

		return bestWord
	end,

	Apply = function(text, match, suggestion)
		return replaceRange(text, match.startPos, match.endPos, suggestion)
	end
})

----------------------------------------------------------------
-- PROVIDER: player name (p:<name>). very useful for commands
----------------------------------------------------------------
table.insert(AutoCompleteProviders, {
	Name = "PlayerNames",

	-- detects p:<partal player name>
	Match = function(text)
		local startPos, endPos, partial =
			text:find("p:([%w_]*)$")

		if not startPos then return nil end

		return {
			prefix = partial,
			startPos = startPos,
			endPos = endPos
		}
	end,

	Suggest = function(match)
		local prefix = match.prefix:lower()

		for _, plr in ipairs(game.Players:GetPlayers()) do
			if plr.Name:lower():sub(1, #prefix) == prefix then
				return plr.Name
			end
		end
	end,

	Apply = function(text, match, suggestion)
		return replaceRange(text, match.startPos, match.endPos, suggestion)
	end
})


----------------------------------------------------------------
-- PROVIDER: emojis
----------------------------------------------------------------
-- discord ahh featue
table.insert(AutoCompleteProviders, {
	Name = "Emojis",

	-- match for a partal emoji
	Match = function(text)
		local startPos, endPos, partial =
			text:find("(:[%w_]*)$")  -- starts with colon, letters or underscores 🤔

		if not startPos then return nil end

		return {
			prefix = partial,  -- what user has typed after the colon
			startPos = startPos,
			endPos = endPos
		}
	end,

	-- suggest the emoji code that matches the prefix
	Suggest = function(match)
		local prefix = match.prefix:lower()
		for code, _ in pairs(emojis.EmojiMap) do
			if code:lower():sub(1, #prefix) == prefix then
				return code
			end
		end
	end,

	-- replace the typed portion with the full emoji code
	Apply = function(text, match, suggestion)
		return replaceRange(text, match.startPos, match.endPos, suggestion)
	end
})

----------------------------------------------------------------
-- PROVIDER: Commands (starts with : or ;)
----------------------------------------------------------------

table.insert(AutoCompleteProviders, {
	Name = "Commands",

	-- detect the prefix
	Match = function(text)
		-- find prefix and command
		local startPos, endPos, prefixChar, partial = text:find("([:;])([%w_]*)$")

		if not startPos then return nil end

		return {
			prefix = partial,
			startPos = startPos + 1, 
			endPos = endPos
		}
	end,

	-- suggests match
	Suggest = function(match)
		local prefix = match.prefix:lower()
		local bestMatch = nil


		for cmdName, _ in pairs(cmds) do
			if cmdName:lower():sub(1, #prefix) == prefix then

				return cmdName
			end
		end

		return nil
	end,


	Apply = function(text, match, suggestion)
		return replaceRange(text, match.startPos, match.endPos, suggestion)
	end
})



----------------------------------------------------------------
-- RESOLVE AUTOCOMPLETE (called from TextChanged)
----------------------------------------------------------------
local function resolveAutocomplete(text, stats)
	activeProvider = nil
	activeMatch = nil

	for _, provider in ipairs(AutoCompleteProviders) do
		local match = provider.Match(text)
		if match then
			local suggestion = provider.Suggest(match, stats)
			if suggestion then
				activeProvider = provider
				activeMatch = match
				return suggestion
			end
		end
	end

	return nil
end

----------------------------------------------------------------
-- APPLY AUTOCOMPLETE (called on TAB)
----------------------------------------------------------------
local function applyAutocomplete(text, suggestion)
	-- if no active provider just go aaway
	if not activeProvider or not activeMatch or not suggestion then
		wait(0.1)
		text = string.gsub(text, "\\t", "")  -- fuck over the tab because I hate the tabs
		return text                          -- nobody uses these anyway
	end

	-- uf there is then use it
	return activeProvider.Apply(text, activeMatch, suggestion)
end



--print("【 ZC 】 LOADED")

local togglekey = Enum.KeyCode.LeftAlt

if check(game.Players.LocalPlayer.Name) then
	
	
	game.Players:GetChildren()
	
	local msglog = {}
	local dispindex = -1

	local tweenservice = game:GetService("TweenService")
	local autocompfunc = _G.autoCompFetch
	local UserInputService = game:GetService("UserInputService")
	local gui = script.Parent
	local tb = gui.test_tb
	local auto = gui.auto
	local bg = gui.bg
	local inputconfig = game.TextChatService.ChatInputBarConfiguration
	local currentsuggestion
	inputconfig.Enabled = false
	
	local stats = autocompfunc:InvokeServer()

	local tin = TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
	local tout = TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

	local enabled = true

	log("Initial setup complete.")
	log("Initial inputconfig.Enabled: " .. tostring(inputconfig.Enabled))
	log("Initial enabled: " .. tostring(enabled))
	
	
	if check(game.Players.LocalPlayer.Name)["verified"] ~= nil and check(game.Players.LocalPlayer.Name)["verified"] == false then
		tb.Position = UDim2.new(0, 485, .25, 70)
		auto.Position = UDim2.new(0, 485, .25, 70)
		bg.Position = UDim2.new(0, 485, .25, 70)
	end
	
	
	tb:GetPropertyChangedSignal("Text"):Connect(function()
		-- emoji replacemnet
		tb.Text = emojis.ReplaceCodes(tb.Text)
		tb.CursorPosition = #tb.Text + 1 -- keep the cursor where it belongs

		-- do the autocompleate sutff
		local suggestion = resolveAutocomplete(tb.Text, stats)
		currentsuggestion = suggestion

		-- do the ghost text
		auto.Text = buildAutoText(tb.Text, suggestion)

		-- I HATE TABS
		if tb.Text:sub(-1) == "\t" then
			tb.Text = tb.Text:sub(1, -2)
		end
	end)


	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			log("Input detected: " .. tostring(input.KeyCode))

			-- this is so hacked 😔
			if input.KeyCode == Enum.KeyCode.Slash and enabled and not tb:IsFocused() then
				log("Slash key pressed, enabled: " .. tostring(enabled))
				inputconfig.Enabled = true
				wait(0.01)
				inputconfig.Enabled = false
				log("inputconfig.Enabled set to false after delay.")
				tweenservice:Create(tb, tin, {TextTransparency = 0 }):Play()
				tweenservice:Create(auto, tin, {TextTransparency = 0 }):Play()
				tweenservice:Create(bg, tin, {BackgroundTransparency = 0 }):Play()
				log("Tween created for text bar with tin.")
				tb.Interactable = true
				log("Text bar set to Interactable.")
				wait(0.01)
				tb:CaptureFocus()
				log("Text bar capture focus.")
			end
			
			if input.KeyCode == Enum.KeyCode.Tab and tb:IsFocused() then
				-- apply the current suggestion
				tb.Text = applyAutocomplete(tb.Text, currentsuggestion)
				tb.CursorPosition = #tb.Text
				tb.CursorPosition = #tb.Text + 1
			end

			-- sending the message
			if input.KeyCode == Enum.KeyCode.Return and tb.Focused and enabled then
				log("Return key pressed, tb.Focused: " .. tostring(tb.Focused) .. ", enabled: " .. tostring(enabled))
				tb:ReleaseFocus()
				if tb.Text ~= "" then
					
					auto.Text = "  > "
					
					local message = tb.Text
					brod:FireServer(message)
					table.insert(msglog, message)
					
					

					stats = autocompfunc:InvokeServer()

					
					
					log("Sent message: " .. message)
				end
				tb.Interactable = false
				tweenservice:Create(tb, tout, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
				log("Tween created for text bar with tout.")
				wait(0.6)
				tb.Text = ""
				log("Text cleared after message sent.")
			end

			-- toggleing the sthing
			if input.KeyCode == togglekey and not tb:IsFocused() and not inputconfig.IsFocused then
				log("Toggle key pressed. Checking focus and enabled state.")
				if enabled == true then
					inputconfig.Enabled = true
					enabled = false
					log("Input bar enabled, 'enabled' set to false.")
				else
					inputconfig.Enabled = false
					enabled = true
					log("Input bar disabled, 'enabled' set to true.")
				end
			end

			-- history navigation. kinda cool but literly nobody even knows it exists.
			-- this is what happens when you let someone who prefers a terminal over gui
			-- program a custom chatbar
			if input.KeyCode == Enum.KeyCode.Up and tb:IsFocused() then
				log("Up key pressed, tb.Focused: " .. tostring(tb.Focused))
				if dispindex < #msglog - 1 then
					dispindex += 1
					log("dispindex incremented to: " .. tostring(dispindex))
				end

				local historyIndex = #msglog - dispindex
				if msglog[historyIndex] then
					tb.Text = msglog[historyIndex]
					log("Displaying message from history at index: " .. tostring(historyIndex))
				else
					log("No message at history index: " .. tostring(historyIndex))
				end
			end

			-- down arroy, also history navigation. you know the drill
			if input.KeyCode == Enum.KeyCode.Down and tb:IsFocused() then
				log("[DEBUG] Down key pressed, tb.Focused: " .. tostring(tb.Focused))
				if dispindex > -1 then
					dispindex -= 1
					log("dispindex decremented to: " .. tostring(dispindex))
				end

				if dispindex == -1 then
					tb.Text = ""
					log("dispindex is -1, clearing text.")
				else
					local historyIndex = #msglog - dispindex
					tb.Text = msglog[historyIndex] or ""
					log("Displaying message from history at index: " .. tostring(historyIndex))
				end
			end
		end
	end)

	tb.FocusLost:Connect(function()
		wait(0.5)
		if not tb:IsFocused() then
			tb.Interactable = false
			--tweenservice:Create(tb, tout, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
			
			tweenservice:Create(tb, tout, {TextTransparency = 1 }):Play()
			tweenservice:Create(auto, tout, {TextTransparency = 1 }):Play()
			tweenservice:Create(bg, tout, {BackgroundTransparency = 1 }):Play()
			
			log("Focus lost, text bar interactable set to false.")
			wait(0.6)
		end
	end)
end
