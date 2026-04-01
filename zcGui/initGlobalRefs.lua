-- same thing as the server side one, boring i know.

local refs = game.ReplicatedStorage.zcRep:GetChildren()

for _, ref in ipairs(refs) do
	_G[ref.Name] = ref
	--print("[CLIENT] -- initilized _G." .. ref.Name)
end
--print("[CLIENT] done initlizing")