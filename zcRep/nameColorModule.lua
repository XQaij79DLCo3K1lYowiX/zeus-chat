-- skidded from te dev fourm ovbiously
local Utilize = {}


local NameColors = {
	Color3.new(253/255, 41/255, 67/255), -- BrickColor.new("Bright red").Color,
	Color3.new(1/255, 162/255, 255/255), -- BrickColor.new("Bright blue").Color,
	Color3.new(2/255, 184/255, 87/255), -- BrickColor.new("Earth green").Color,
	BrickColor.new("Bright violet").Color,
	BrickColor.new("Bright orange").Color,
	BrickColor.new("Bright yellow").Color,
	BrickColor.new("Light reddish violet").Color,
	BrickColor.new("Brick yellow").Color,
}


function Utilize.GetNameColor(Username)
	local Value = 0
	local NumName = #Username
	for index = 1, NumName do
		local CValue = string.byte(string.sub(Username, index, index))
		local ReverseIndex = NumName - index + 1
		if NumName % 2 == 1 then
			ReverseIndex = ReverseIndex - 1
		end
		if ReverseIndex % 4 >= 2 then
			CValue = -CValue
		end
		Value = Value + CValue
	end
	return NameColors[(Value % #NameColors) + 1]
end

return Utilize