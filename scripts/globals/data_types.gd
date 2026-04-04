# ── DataTypes ────────────────────────────────────────────────
# 全局枚举定义文件
#
# 使用 class_name 后，任何脚本都可以直接写 DataTypes.Tools.AxeWood
# 不需要 autoload，Godot 会自动全局识别 class_name
# ─────────────────────────────────────────────────────────────
class_name DataTypes

# 工具类型
# 玩家手持的工具决定了能对哪些物件造成作用
enum Tools {
	None,         # 空手
	AxeWood,      # 斧头 → 砍树
	TillGround,   # 锄头 → 耕地
	WaterCrops,   # 浇水壶 → 给作物浇水
	PlantCorn,    # 玉米种子 → 在耕地上种植
	PlantTomato   # 番茄种子 → 在耕地上种植
}

# 作物生长阶段
# 每天结束时作物会推进到下一个阶段
enum GrowthStates {
	Seed,          # 种子（刚种下）
	Germination,   # 发芽
	Vegetative,    # 生长期
	Reproduction,  # 繁殖期
	Maturity,      # 成熟（可以收获了）
	Harvesting     # 收获中
}
