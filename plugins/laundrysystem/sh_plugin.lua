local PLUGIN = PLUGIN

PLUGIN.name = "Lite Network Laundry System"
PLUGIN.author = "Riggs Mackay | Modified by Frosty"
PLUGIN.description = "Allows Civil Worker's Union to do laundry work."

ix.config.Add("laundryWashTime", 30, "The time in seconds it takes to wash a cloth.", nil, {
	data = {min = 1, max = 300},
	category = "Laundry"
})

ix.config.Add("laundryDirtyDelay", 5, "Delay between producing dirty clothes.", nil, {
	data = {min = 1, max = 600},
	category = "Laundry"
})

ix.config.Add("laundryCartMin", 5, "Minimum amount of clothes a cart must hold for rewards.", nil, {
	data = {min = 1, max = 100},
	category = "Laundry"
})

ix.config.Add("laundryCartMax", 20, "Maximum amount of clothes a cart can hold for rewards.", nil, {
	data = {min = 1, max = 100},
	category = "Laundry"
})

ix.config.Add("laundryTokensPerCloth", 3, "Amount of tokens given per clean cloth.", nil, {
	data = {min = 0, max = 100},
	category = "Laundry"
})

ix.config.Add("laundryRewardTokens", false, "Whether or not players receive tokens automatically for laundry work.", nil, {
	category = "Laundry"
})

ix.lang.AddTable("english", {
	laundryNoAccess = "You do not have permission to use this!",
	laundryReward = "For washing %s clothes, you have gained %s.",
	laundryRewardSingle = "For washing 1 cloth, you have gained %s.",
	laundryProcessed = "You have processed %s clothes.",
	laundryProcessedSingle = "You have processed 1 cloth.",
	laundryCleanClothes = "%s clean clothes",
	laundryDirtyClothes = "%s dirty clothes",
	laundryClothDesc = "A cloth that needs to be washed in the washing machine.",
	laundryClean = "Clean",
	laundryDirty = "Dirty",
	washingMachineDesc = "A device that washes clothes.",
	laundryCartDesc = "A device that holds and processes clothes.",
	laundryPipeDesc = "A pipe through which clothes come down.",
	laundryMinClothes = "You need at least %s clothes to process!",
	laundryPipeFull = "There are too many unprocessed clothes! Please process them first."
})

ix.lang.AddTable("korean", {
	["Laundry"] = "세탁",
	laundryNoAccess = "이 장치를 사용할 권한이 없습니다!",
	laundryReward = "세탁물 %s개를 세탁하여 %s을 받았습니다.",
	laundryRewardSingle = "세탁물 1개를 세탁하여 %s을 받았습니다.",
	laundryProcessed = "세탁물 %s개를 성공적으로 처리했습니다.",
	laundryProcessedSingle = "세탁물 1개를 성공적으로 처리했습니다.",
	laundryCleanClothes = "깨끗한 세탁물 %s개",
	laundryDirtyClothes = "더러운 세탁물 %s개",
	["Laundry Cloth"] = "세탁물",
	laundryClothDesc = "세탁기에 빨아야 하는 옷가지입니다.",
	laundryClean = "깨끗함",
	laundryDirty = "더러움",
	["Washing Machine"] = "세탁기",
	washingMachineDesc = "세탁물을 세탁하는 장치입니다.",
	["Laundry Cart"] = "세탁 카트",
	laundryCartDesc = "세탁물을 담고 사용하여 세탁물을 처리합니다.",
	["Laundry Pipe"] = "세탁물 배관",
	laundryPipeDesc = "세탁물이 내려오는 배관입니다.",
	laundryMinClothes = "세탁물을 처리하려면 최소 %s개가 필요합니다!",
	laundryPipeFull = "처리하지 않은 세탁물이 많습니다! 먼저 세탁물을 처리하세요."
})

function PLUGIN:CanUseLaundry(ply)
	return not ply:IsCombine()
end

if (SERVER) then
	function PLUGIN:SaveData()
		local data = {}

		local entities = {
			"ix_laundry_cart",
			"ix_laundry_pipe",
			"ix_washing_machine",
			"ix_washing_machine_small",
			"ix_laundry_cart_small",
		}

		for _, class in ipairs(entities) do
			for _, v in ipairs(ents.FindByClass(class)) do
				data[#data + 1] = {
					class = class,
					pos = v:GetPos(),
					angles = v:GetAngles()
				}
			end
		end

		self:SetData(data)
	end

	function PLUGIN:LoadData()
		local data = self:GetData()

		if (data) then
			for _, v in ipairs(data) do
				local entity = ents.Create(v.class)
				entity:SetPos(v.pos)
				entity:SetAngles(v.angles)
				entity:Spawn()
			end
		end
	end
end
