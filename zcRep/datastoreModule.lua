-- datastore stuff. Dont feel like adding any comments
-- this is so cool

local DataStoreService = game:GetService("DataStoreService")

local DataHandler = {}
DataHandler.__index = DataHandler


function DataHandler.new(name)
	local self = setmetatable({}, DataHandler)
	self.store = DataStoreService:GetDataStore(name)
	return self
end


function DataHandler:Get(key)
	local success, data = pcall(function()
		return self.store:GetAsync(key)
	end)
	if success then
		return data
	else
		warn("GetAsync failed:", data)
		return nil
	end
end


function DataHandler:Set(key, value)
	local success, err
	for i = 1, 3 do
		success, err = pcall(function()
			self.store:SetAsync(key, value)
		end)
		if success then break end
		task.wait(1)
	end

	if not success then
		warn("SetAsync failed:", err)
	end
end


function DataHandler:Update(key, callback)
	local success, err
	for i = 1, 3 do
		success, err = pcall(function()
			self.store:UpdateAsync(key, callback)
		end)
		if success then break end
		task.wait(1)
	end

	if not success then
		warn("UpdateAsync failed:", err)
	end
end

return DataHandler
