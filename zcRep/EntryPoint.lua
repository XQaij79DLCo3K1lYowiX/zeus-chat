local loader = {}
local Players = game:GetService("Players")



-- helper: find user entry in config.users
local function getUserEntry(username, config)
	for key, value in pairs(config.users) do
		if type(key) == "number" then
			if value == username then
				return {
					name = value,
					data = nil
				}
			end
		else
			if key == username then
				return {
					name = key,
					data = value
				}
			end
		end
	end

	return nil
end

-- checks if friends with owner, wow
local function isFriendsWithOwner(player, ownerId)
	if not player or not ownerId then return false end

	local success, result = pcall(function()
		return player:IsFriendsWith(ownerId)
	end)

	return success and result
end



-- loads modules that MIGHT not exist yet by waiting for them to exist
-- youere supposed to pass _G.module or somthing
function loader.safeload(moduleRef)
	local timeout = 0
	local maxWait = 5

	while not moduleRef and timeout < maxWait do
		timeout = timeout + task.wait()
	end
	if not moduleRef then
		error("Module failed to initialize within the timeout period.")
	end
	return require(moduleRef)
end



-- loads config, fallsback to default if nessacary
function loader.loadconfig()
	
	local success, result = xpcall(function()
		return loader.safeload(_G.config)
	end, function(err)
		return debug.traceback(err)
	end)

	if success then
		_G.loadedconf = result  -- lmaooo, init global refs could have totaly just done this 
		return result
	else
		warn("!! Config Load Failed !!")
		_G.defaltConfig = true
		--warn(result) -- commented out because it doenst work like how I would like
		local conf = require(script.fallback)
		_G.loadedconf = conf  
		return conf
	end
end

function loader.checkUser(username, config)
	local permissionMode = config["permissionMode"] or "off"
	local ownerId = game.CreatorId

	local player = Players:FindFirstChild(username)
	local userEntry = getUserEntry(username, config)

	local allowed = false
	
	if player and player.UserId == ownerId then
		allowed = true
	end

	if permissionMode == "all" then
		allowed = true

	elseif permissionMode == "off" then
		-- owner only
		if player and player.UserId == ownerId then
			allowed = true
		end

	elseif permissionMode == "whitelist" then
		if userEntry then
			allowed = true
		end

	elseif permissionMode == "friends" then
		if player and isFriendsWithOwner(player, ownerId) then
			allowed = true
		end
	end

	if not allowed then
		return nil -- deny access
	end

	-- return structured result
	if userEntry then
		return {
			username = userEntry.name,
			data = userEntry.data -- may be nil
		}
	else
		-- allowed but no config entry
		return {
			username = username,
			data = nil
		}
	end
end



return loader
