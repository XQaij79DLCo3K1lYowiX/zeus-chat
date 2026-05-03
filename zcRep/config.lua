local config = {
	
	-- the mode of permission. can be "off", "friends" or "whitelist"
	-- off means anyone can use the chat
	-- friends means only friends of the owner can use the chat
	-- whitelist means only the users in the "users" table can use the chat
	permissionMode = "friends",
	
	-- the users that will be able to use zeuschat, given whitelist is enabled
	-- users with data will have data applied even if whitelist is disabled
	-- please put any new names in qoutes, and put a comma at the end unless you want an error
	
	-- If a user is unverified or you want to add a gradient to their name, refer to the examples
	-- with data (8zmksSIIm7V5CbFYyzgw and Zeus_gameover)
	users = {
		"lukiebubsAlt",
		"d3wys",
		["8zmksSIIm7V5CbFYyzgw"] = {  -- example of user data
			verified = false,
			gradient = {
				"#890aff",
				"#b10aff"
			},
		},
		
		
		
		["Zeus_gameover"] = {
			verified = false
		}
	},
	
	--[[
	
	
	]]
	
	
	-- adonis auto complete for commands. if this is enabled and you do not
	-- have adonis or you do have adonis but not my plugin installed, it will
	-- fuck everything up.
	
	adonisAutoComplete = false,
	
	
	-- join leave messages, I just think they look pretty
	jlmessages = true,
	
	
	
	-- loaded message. lets you know everything is functional
	
	loadedMessage = true,
	
	
	-- stuff related to updates. not recommended to mess with it.
	-- if the update warning is annoying you, disable it. But don't be
	-- suprised if zeus chat stops working once i cut support for that
	-- version.
	
	updateWarning = true,
	version = "0.2.4",    -- dont change plesae
	
	-- weither or not to cache the current ZC version in a datastore. Good if you abandoning
	-- and still want the chat to work. Not recommended as it could be unsafe. 
	cacheversion = false,  
	
	
	
	-- zeus relay. I actually havent open sourced zeus relay yet
	-- so the only reason you should be enabling this is if I gave you it
	
	zeusRelayEnabled = false,
	zeusRelayKey = "", 
	zeusRelayUrl = ""
	
	
	
	
}

return config