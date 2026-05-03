-- make it so stuff doesnt have to have like a hardcoded location
-- couldve done better, who cares

-- if any contributers wanna change this to a better system, whatever, go ahead.
_G.ep = game.ReplicatedStorage.zcRep.EntryPoint
local refs = game.ReplicatedStorage.zcRep:GetChildren()


for _, ref in ipairs(refs) do
	if ref.Name == "EntryPoint" then
		continue
	end
	_G[ref.Name] = ref
	--print("[SERVER] -- initilized _G." .. ref.Name)
end
--print("[SERVER] done initlizing")
