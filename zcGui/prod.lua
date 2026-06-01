-- handles ALL of the gui and some client side stuff.
-- visuals, quality of life shit, etc.


wait(0.01) -- give time for init to happen
local ep = require(_G.ep) 

local brod = _G.brodcastRemote
local rec = _G.receiveRemote
local Service = game:GetService("TextChatService")
local emojis = ep.safeload(_G.emojiModule)
local snd = _G.snd
local config = ep.loadconfig()
local cmds = {}

local debug = false


-- PRIVATE CHAT STATE STATE VARIABLES
local isPrivateChatting = false
local privateChatTarget = ""
local lastPrivateUser = nil
local basePrompt = "  > "
local currentPrompt = basePrompt
local paddingSpaces = ""

--[[
local waits = 0          -- this wait / timeout thing CANNOT be efficient. whatevre.
while not emoji do 		 -- ^ ok i got rid of it. wow. 
	if waits > 10 then
		error("timeout")
		return
	end
	waits += 1
	wait(0.4)
	emoji = _G.emojiModule
end


local emojis = require(emoji)
]]
--[[
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
]] 


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




local function log(message)  -- was acutally amazing for debugging. 
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


-- UTILITY: replace a specific character range in a string
local function replaceRange(text, startPos, endPos, replacement)
	return text:sub(1, startPos - 1)
		.. replacement
		.. text:sub(endPos + 1)
end


-- Utility: extract trailing non-space token
local function getLastWord(text)
	text = text:match("^(.-)%s*$")
	return text:match("(%S+)$") or ""
end


-- Utility: build ghost autocomplete text, provider aware
local function buildAutoText(text, suggestion)
	if not suggestion then
		return currentPrompt
	end

	if activeMatch and activeMatch.prefix then
		local remaining = suggestion:sub(#activeMatch.prefix + 1)
		return currentPrompt
			.. string.rep(" ", #text)
			.. remaining
	end

	local lastWord = getLastWord(text)
	local remaining = suggestion:sub(#lastWord + 1)

	return currentPrompt
		.. string.rep(" ", #text)
		.. remaining
end

-- provider: common words, uses a datastore and has server side logic too
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

-- provider: player name (p:<name>). very useful for commands :100:
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



-- provider: emojis
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
		log("applied emoji ac")
		return replaceRange(text, match.startPos, match.endPos, suggestion)
	end
})


-- provider: Commands (starts with : or ;), might change and stuff

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

-- private chat, dont feel like going in depth with comments
table.insert(AutoCompleteProviders, {
	Name = "PrivateChat",

	Match = function(text)
		-- Find where the "!private " command and its trailing spaces end
		local cmdStart, cmdEnd = text:find("^!private%s+")
		if not cmdStart then return nil end

		-- The partial username is everything after the command prefix
		local partial = text:sub(cmdEnd + 1)

		-- If there are trailing spaces after the username, don't match
		if partial:find("%s") then return nil end

		return {
			prefix = partial,
			startPos = cmdEnd + 1,  -- Start replacing right after the "!private " text
			endPos = #text          -- Replace up to the current end of the string
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




-- resolve autocomplete (called from TextChanged) (evil)
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


-- apply autocomplete (called on TAB) (amazing)
local function applyAutocomplete(text, suggestion)
	log("apply called")
	-- if no active provider just go aaway
	if not activeProvider or not activeMatch or not suggestion then
		wait(0.1)
		text = string.gsub(text, "\\t", "")  -- fuck over the tab because I hate the tabs
		return text                          -- nobody uses these anyway
	end	

	-- uf there is then use it
	return activeProvider.Apply(text, activeMatch, suggestion)
end

local function initDesktopGUI()
	local msglog = {}
	local dispindex = -1

	local player = game.Players.LocalPlayer
	local tweenservice = game:GetService("TweenService")
	local autocompfunc = _G.autoCompFetch
	local UserInputService = game:GetService("UserInputService")

	local gui = script.Desktop
	local tb = gui.test_tb
	local auto = gui.auto
	local bg = gui.bg

	for _, i in ipairs(gui:GetChildren()) do
		i.Parent = script.Parent
	end

	local inputconfig = game.TextChatService.ChatInputBarConfiguration
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local currentsuggestion

	inputconfig.Enabled = false

	local stats = autocompfunc:InvokeServer()

	local tin = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	local tout = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)

	local enabled = true
	local visible = false



	log("Chat UI init complete")

	-- PRIVATE CHAT LIFECYCLE FUNCTIONS
	local function startPrivateChat(targetUser)
		isPrivateChatting = true
		privateChatTarget = targetUser
		currentPrompt = " [" .. targetUser .. "] > "
		-- Calculate how many spaces we need to shift the cursor to align perfectly
		paddingSpaces = string.rep(" ", #currentPrompt - #basePrompt)

		auto.Text = currentPrompt
		tb.Text = paddingSpaces
		tb.CursorPosition = #tb.Text + 1
		log("Started private chat channel with: " .. targetUser)
	end

	local function stopPrivateChat()
		if not isPrivateChatting then return end
		isPrivateChatting = false
		lastPrivateUser = privateChatTarget
		privateChatTarget = ""
		currentPrompt = basePrompt
		paddingSpaces = ""

		-- Clean up any residual typed text when dropping back to public
		local cleanText = tb.Text:match("^%s*(.*)$") or ""
		tb.Text = cleanText
		auto.Text = basePrompt
		tb.CursorPosition = #tb.Text + 1
		log("Exited private chat channel")
	end

	local function showBar(reason)
		if visible then return end
		visible = true
		log("Showing chat bar | reason: " .. (reason or "unknown"))
		tweenservice:Create(tb, tin, {TextTransparency = 0}):Play()
		tweenservice:Create(auto, tin, {TextTransparency = 0}):Play()
		tweenservice:Create(bg, tin, {BackgroundTransparency = 0}):Play()
		tb.Interactable = true
	end

	local function hideBar(reason)
		if not visible then return end
		visible = false
		log("Hiding chat bar | reason: " .. (reason or "unknown"))
		tweenservice:Create(tb, tout, {TextTransparency = 1}):Play()
		tweenservice:Create(auto, tout, {TextTransparency = 1}):Play()
		tweenservice:Create(bg, tout, {BackgroundTransparency = 1}):Play()
		tb.Interactable = false
	end

	bg.MouseEnter:Connect(function()
		if enabled then showBar("hover") end
	end)

	bg.MouseLeave:Connect(function()
		if not tb:IsFocused() then hideBar("hover leave") end
	end)

	bg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and enabled then
			showBar("click")
			tb:CaptureFocus()
		end
	end)

	local user = ep.checkUser(player.Name, config)
	if user.data ~= nil and user.data["verified"] ~= nil and user.data["verified"] == false then
		tb.Position = UDim2.new(0, 485, .25, 70)
		auto.Position = UDim2.new(0, 485, .25, 70)
		bg.Position = UDim2.new(0, 485, .25, 70)
		log("Adjusted UI for unverified user")
	end

	-- TEXT CHANGED INTERCEPTOR
	tb:GetPropertyChangedSignal("Text"):Connect(function()
		-- Safely check if the backspace button tried eating into the required padding structure
		if isPrivateChatting then
			if #tb.Text < #paddingSpaces or tb.Text:sub(1, #paddingSpaces) ~= paddingSpaces then
				--stopPrivateChat()
				--return
				tb.Text = paddingSpaces
			end
		end

		-- Isolate the user's actual text content from the padding spaces
		local cleanText = isPrivateChatting and tb.Text:sub(#paddingSpaces + 1) or tb.Text

		-- Run substitutions strictly against the clean text stream
		local replacedClean = emojis.ReplaceCodes(cleanText)
		if replacedClean ~= cleanText then
			tb.Text = (isPrivateChatting and paddingSpaces or "") .. replacedClean
			tb.CursorPosition = #tb.Text + 1
			return
		end

		tb.CursorPosition = #tb.Text + 1

		local suggestion = resolveAutocomplete(cleanText, stats)
		currentsuggestion = suggestion

		-- Pass cleanText down to ensure ghost character generation maps one-to-one
		auto.Text = buildAutoText(cleanText, suggestion)

		if tb.Text:sub(-1) == "\t" then
			tb.Text = tb.Text:sub(1, -2)
			log("Tab character stripped from input")
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			log("Key pressed: " .. tostring(input.KeyCode))

			if input.KeyCode == Enum.KeyCode.Slash and enabled and not tb:IsFocused() then
				inputconfig.Enabled = true
				task.wait()
				inputconfig.Enabled = false
				showBar("slash")
				tb:CaptureFocus()
			end

			-- Tab Completion
			if input.KeyCode == Enum.KeyCode.Tab and tb:IsFocused() then
				log("Applying autocomplete")
				local cleanText = isPrivateChatting and tb.Text:sub(#paddingSpaces + 1) or tb.Text
				local completedClean = applyAutocomplete(cleanText, currentsuggestion)

				tb.Text = (isPrivateChatting and paddingSpaces or "") .. completedClean
				tb.CursorPosition = #tb.Text + 1
			end

			if input.KeyCode == togglekey and not tb:IsFocused() and not inputconfig.IsFocused then
				if enabled then
					inputconfig.Enabled = true
					enabled = false
				else
					inputconfig.Enabled = false
					enabled = true
				end
			end

			-- Manual Bind Channel Controls
			if input.KeyCode == Enum.KeyCode.Left and tb:IsFocused() then
				if isPrivateChatting then
					stopPrivateChat()
				end
			end

			if input.KeyCode == Enum.KeyCode.Right and tb:IsFocused() then
				if not isPrivateChatting and lastPrivateUser ~= nil then
					startPrivateChat(lastPrivateUser)
				end
			end

			-- Command Line History Navigation
			if input.KeyCode == Enum.KeyCode.Up and tb:IsFocused() then
				if dispindex < #msglog - 1 then
					dispindex += 1
				end

				local historyIndex = #msglog - dispindex
				local historyMessage = msglog[historyIndex] or ""

				-- Retain padding spaces if currently inside an active channel
				tb.Text = (isPrivateChatting and paddingSpaces or "") .. historyMessage
				log("History up -> index: " .. tostring(historyIndex))
			end

			if input.KeyCode == Enum.KeyCode.Down and tb:IsFocused() then
				if dispindex > -1 then
					dispindex -= 1
				end

				if dispindex == -1 then
					tb.Text = isPrivateChatting and paddingSpaces or ""
					log("History cleared (back to empty)")
				else
					local historyIndex = #msglog - dispindex
					local historyMessage = msglog[historyIndex] or ""
					tb.Text = (isPrivateChatting and paddingSpaces or "") .. historyMessage
					log("History down -> index: " .. tostring(historyIndex))
				end
			end
		end
	end)

	tb.FocusLost:Connect(function(enterPressed)
		log("TextBox focus lost | enterPressed: " .. tostring(enterPressed))

		if enterPressed and enabled then
			-- Extract target text ignoring layout padding
			local rawText = tb.Text
			local cleanText = isPrivateChatting and rawText:sub(#paddingSpaces + 1) or rawText

			if cleanText ~= "" then
				-- Intercept and run !private routing checks
				if cleanText:match("^!private%s+%w+") then
					local targetUser = cleanText:match("^!private%s+(%w+)")

					snd:Fire("init_private", targetUser)
					startPrivateChat(targetUser)

					-- Refocus immediately so they can begin messaging seamlessly
					task.defer(function() tb:CaptureFocus() end)
					return 
				end

				-- Dynamic message payload distribution
				if isPrivateChatting then
					snd:Fire("send_private", privateChatTarget, cleanText)
					log("Private message sent to " .. privateChatTarget .. ": " .. cleanText)
				else
					snd:Fire("send", cleanText)
					log("Public message sent: " .. cleanText)
				end

				table.insert(msglog, cleanText)
				stats = autocompfunc:InvokeServer()
			end

			-- Maintain chat structural states on frame clearing
			tb.Text = isPrivateChatting and paddingSpaces or ""
			auto.Text = currentPrompt
			hideBar("message sent")
		else
			task.delay(0.2, function()
				if not tb:IsFocused() then
					hideBar("focus lost")
				end
			end)
		end
	end)
end


local function initMobileGUI()
	local icon = require(script.Icon) -- used some gay module for the icon, works well.

	local tweenservice = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local TextChatService = game:GetService("TextChatService")

	local autocompfunc = _G.autoCompFetch
	
	local effect = Instance.new("HapticEffect")
	effect.Type = Enum.HapticEffectType.UIClick
	effect.Parent = workspace
	
	local inputconfigbar = TextChatService.ChatInputBarConfiguration
	local inputconfigbox = TextChatService.ChatWindowConfiguration

	local gui = script.Mobile

	local tb = gui.bg.test_tb
	local auto = gui.bg.auto
	local bg = gui.bg

	for _, i in ipairs(script.Mobile:GetChildren()) do
		i.Parent = script.Parent
	end

	local stats = autocompfunc:InvokeServer()

	local visible = false
	local animating = false

	local currentsuggestion
	local lasttext = ""

	local doubleTapWindow = 0.35
	local lastTap = 0

	-- focus is lost and it breaks the double tap to autocomplete, this helps
	local autocompletePrimed = false

	-- does nothing and sucks
	local suppressHideUntil = 0

	local tin = TweenInfo.new(
		0.2,
		Enum.EasingStyle.Cubic,
		Enum.EasingDirection.Out
	)

	local tout = TweenInfo.new(
		0.18,
		Enum.EasingStyle.Cubic,
		Enum.EasingDirection.In
	)

	-- make it not there
	bg.BackgroundTransparency = 1
	tb.TextTransparency = 1
	auto.TextTransparency = 1

	bg.Visible = false
	tb.Interactable = false


	local function showBar() -- you'll never guess what this does
		if visible or animating then
			return
		end

		animating = true
		visible = true

		bg.Visible = true

		-- disable roblox chat, core GUI sucks and loves to sit on top of everything
		inputconfigbar.Enabled = false
		inputconfigbox.Enabled = false

		tb.Interactable = true

		tweenservice:Create(bg, tin, {
			BackgroundTransparency = 0
		}):Play()

		tweenservice:Create(tb, tin, {
			TextTransparency = 0
		}):Play()

		tweenservice:Create(auto, tin, {
			TextTransparency = 0
		}):Play()

		task.delay(tin.Time, function()
			animating = false

			-- wehn its done playing pritty animation its time to start typing
			tb:CaptureFocus()
		end)
	end

	local function hideBar() -- this ones hard to guess what it does
		if not visible or animating then
			return
		end

		animating = true
		visible = false

		tb.Interactable = false

		-- bring back terrible default chat (zc is better)
		inputconfigbar.Enabled = true
		inputconfigbox.Enabled = true

		tweenservice:Create(bg, tout, {
			BackgroundTransparency = 1
		}):Play()

		tweenservice:Create(tb, tout, {
			TextTransparency = 1
		}):Play()

		tweenservice:Create(auto, tout, {
			TextTransparency = 1
		}):Play()

		task.delay(tout.Time, function()
			bg.Visible = false
			animating = false
		end)
	end

	icon.new() -- use module at top of function to make a pretty button
		:setName("ZCtoggle")
		:setLabel("ZC")
		:oneClick(true)
		:bindEvent("selected", function()
			lasttext = ""
			log("cleared cache")
			showBar()
		end)


	tb:GetPropertyChangedSignal("Text"):Connect(function() -- very important for autocomplete. Runs every time text is changed
		lasttext = tb.Text
		tb.Text = emojis.ReplaceCodes(tb.Text)
		tb.CursorPosition = #tb.Text + 1

		local suggestion = resolveAutocomplete(tb.Text, stats)
		
		if currentsuggestion ~= suggestion  and suggestion ~= ""  and suggestion ~= nil and currentsuggestion ~= nil then
			-- idk it seemed like a cool idea, every time new suggestion, give some feedback
			effect.Type = Enum.HapticEffectType.UIHover
			effect:Play()
		end
		
		currentsuggestion = suggestion

		auto.Text = buildAutoText(tb.Text, suggestion)
	end)

	UserInputService.TouchTap:Connect(function(_, gameProcessed)
		if gameProcessed then
			return
		end

		if not visible then
			return
		end

		local now = tick()

		-- checks if the tap is within doubletap timeframe
		if now - lastTap <= doubleTapWindow then
			
			-- awesome

			-- do nothing becasue this doesnt work
			suppressHideUntil = now + 0.5 

			

			-- force back focus.
				tb:CaptureFocus()
				
			-- apply after bringing back focus otherwise the focus would clear the text in the bar (bad)
			if currentsuggestion then
				tb.Text = applyAutocomplete(lasttext, currentsuggestion)
				tb.CursorPosition = #tb.Text + 1
				
				effect.Type = Enum.HapticEffectType.UINotification -- this makes me happy
				effect:Play()
			else
				tb.Text = lasttext -- no suggestion? just put the text back
			end
			

			-- reset the last tap
			lastTap = 0 
			return
		end

		-- ok now just do it again
		lastTap = now
	end)

	
	-- runs when your not typing in the bar anymore, important
	tb.FocusLost:Connect(function(enterPressed)
		
		if enterPressed then -- ok if its because you hit enter, send it
			local msg = tb.Text

			if msg ~= "" then
				brod:FireServer(msg)
				stats = autocompfunc:InvokeServer()
				effect.Type = Enum.HapticEffectType.UIClick
				effect:Play()
			end

			tb.Text = ""
			auto.Text = ""

			hideBar()
		else
			-- lost focus because you tapped somewhere else on the screen
			-- do important double tap stuff
			task.delay(doubleTapWindow, function()
				if tick() > suppressHideUntil and not tb:IsFocused() then
					hideBar()
				end
			end)
		end
	end)
end


--print("【 ZC 】 LOADED")

local togglekey = Enum.KeyCode.LeftAlt

if ep.checkUser(game.Players.LocalPlayer.Name, config) ~= nil then
	
	if game.RunService:IsStudio() and game.UserInputService.TouchEnabled then
		initMobileGUI()
	elseif not game.UserInputService.KeyboardEnabled and game.UserInputService.TouchEnabled then
		initMobileGUI()
	else
		initDesktopGUI()
	end
	
	--if not game.UserInputService.TouchEnabled then -- will also check if keyboard enabled to acomidate touch screen computers, but for testing it will remain this
	--	initDesktopGUI()                             -- ^ ok i did it
	--else
	--	initMobileGUI()
	--end
end