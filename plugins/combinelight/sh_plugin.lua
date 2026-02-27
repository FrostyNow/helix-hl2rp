PLUGIN.name = "Combine Light"
PLUGIN.author = "robinkooli | Modified by Frosty"
PLUGIN.description = "Portable light sources used to illuminate dark areas in support of Combine operations."

ix.lang.AddTable("english", {
	comlightDesc = "Portable light sources used to illuminate dark areas in support of Combine operations.",
})
ix.lang.AddTable("korean", {
	["Combine Light"] = "콤바인 조명",
	comlightDesc = "어두운 곳에서 콤바인 작전을 수행할 수 있도록 돕는 이동식 광원입니다.",
	Place = "놓기",
})

if (SERVER) then
	function PLUGIN:SaveData()
		local data = {}

		local entities = {
			"hl2_combinelight",
		}

		for _, class in ipairs(entities) do
			for _, v in ipairs(ents.FindByClass(class)) do
				data[#data + 1] = {
					class = class,
					pos = v:GetPos(),
					angles = v:GetAngles(),
					color = v:GetColor()
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
				entity:SetColor(v.color)
				entity:Spawn()
			end
		end
	end
end