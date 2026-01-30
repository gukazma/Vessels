# item_data.gd
# 物品数据类 - 定义物品的属性和效果
class_name ItemData
extends Resource

## ==================== 物品类型枚举 ====================

enum ItemType {
	FOOD,     ## 食物: 恢复饥饿/生命
	WEAPON,   ## 武器: 攻击装备
	MATERIAL, ## 材料: 建造原料
	TOOL,     ## 工具: 特殊用品
	MEDICAL   ## 医疗: 治疗物品
}

## 武器子类型
enum WeaponSubtype {
	NONE,   ## 非武器
	MELEE,  ## 近战
	RANGED  ## 远程
}

## 稀有度
enum Rarity {
	COMMON,  ## 普通 (白色)
	UNCOMMON, ## 优良 (绿色)
	RARE,    ## 稀有 (蓝色)
	EPIC     ## 史诗 (紫色)
}

## ==================== 导出变量 ====================

## 物品ID
@export var id: String = ""

## 物品名称
@export var name_cn: String = ""

## 物品类型
@export var type: ItemType = ItemType.FOOD

## 武器子类型 (仅武器类型有效)
@export var weapon_subtype: WeaponSubtype = WeaponSubtype.NONE

## 稀有度
@export var rarity: Rarity = Rarity.COMMON

## 最大堆叠数量
@export var stack_max: int = 99

## 购买价格 (-1表示不可购买)
@export var price: int = 0

## 物品效果
@export var effects: Dictionary = {}

## 武器伤害 (仅武器类型有效)
@export var damage: float = 0.0

## 武器攻击速度 (仅武器类型有效)
@export var attack_speed: float = 1.0

## 耐久度 (-1表示无耐久度)
@export var durability: int = -1

## 物品描述
@export var description: String = ""

## 图标路径
@export var icon_path: String = ""

## 特殊属性
@export var special: String = ""

## ==================== 方法 ====================

## 从字典创建物品数据
static func from_dict(data: Dictionary) -> ItemData:
	var item = ItemData.new()
	item.id = data.get("id", "")
	item.name_cn = data.get("name", "")
	item.description = data.get("description", "")
	item.price = data.get("price", 0)
	item.stack_max = data.get("stack_max", 99)
	item.icon_path = data.get("icon_path", "")
	item.special = data.get("special", "")
	item.effects = data.get("effects", {})

	# 解析类型
	var type_str = data.get("type", "food").to_lower()
	match type_str:
		"food":
			item.type = ItemType.FOOD
		"weapon":
			item.type = ItemType.WEAPON
		"material":
			item.type = ItemType.MATERIAL
		"tool":
			item.type = ItemType.TOOL
		"medical":
			item.type = ItemType.MEDICAL

	# 解析武器子类型
	if item.type == ItemType.WEAPON:
		var subtype_str = data.get("subtype", "").to_lower()
		match subtype_str:
			"melee":
				item.weapon_subtype = WeaponSubtype.MELEE
			"ranged":
				item.weapon_subtype = WeaponSubtype.RANGED
		item.damage = data.get("damage", 0.0)
		item.attack_speed = data.get("attack_speed", 1.0)
		item.durability = data.get("durability", -1)

	# 解析稀有度
	var rarity_str = data.get("rarity", "common").to_lower()
	match rarity_str:
		"common":
			item.rarity = Rarity.COMMON
		"uncommon", "优良":
			item.rarity = Rarity.UNCOMMON
		"rare", "稀有":
			item.rarity = Rarity.RARE
		"epic", "史诗":
			item.rarity = Rarity.EPIC

	return item


## 转换为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name_cn,
		"type": _type_to_string(),
		"subtype": _weapon_subtype_to_string(),
		"rarity": _rarity_to_string(),
		"stack_max": stack_max,
		"price": price,
		"effects": effects,
		"damage": damage,
		"attack_speed": attack_speed,
		"durability": durability,
		"description": description,
		"icon_path": icon_path,
		"special": special
	}


## 获取类型字符串
func _type_to_string() -> String:
	match type:
		ItemType.FOOD:
			return "food"
		ItemType.WEAPON:
			return "weapon"
		ItemType.MATERIAL:
			return "material"
		ItemType.TOOL:
			return "tool"
		ItemType.MEDICAL:
			return "medical"
		_:
			return "unknown"


## 获取武器子类型字符串
func _weapon_subtype_to_string() -> String:
	match weapon_subtype:
		WeaponSubtype.MELEE:
			return "melee"
		WeaponSubtype.RANGED:
			return "ranged"
		_:
			return ""


## 获取稀有度字符串
func _rarity_to_string() -> String:
	match rarity:
		Rarity.COMMON:
			return "common"
		Rarity.UNCOMMON:
			return "uncommon"
		Rarity.RARE:
			return "rare"
		Rarity.EPIC:
			return "epic"
		_:
			return "common"


## 获取稀有度颜色
func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON:
			return Color.WHITE
		Rarity.UNCOMMON:
			return Color.GREEN
		Rarity.RARE:
			return Color.BLUE
		Rarity.EPIC:
			return Color.PURPLE
		_:
			return Color.WHITE


## 获取中文稀有度名称
func get_rarity_name_cn() -> String:
	match rarity:
		Rarity.COMMON:
			return "普通"
		Rarity.UNCOMMON:
			return "优良"
		Rarity.RARE:
			return "稀有"
		Rarity.EPIC:
			return "史诗"
		_:
			return "未知"


## 获取中文类型名称
func get_type_name_cn() -> String:
	match type:
		ItemType.FOOD:
			return "食物"
		ItemType.WEAPON:
			return "武器"
		ItemType.MATERIAL:
			return "材料"
		ItemType.TOOL:
			return "工具"
		ItemType.MEDICAL:
			return "医疗"
		_:
			return "未知"


## 检查是否可堆叠
func is_stackable() -> bool:
	return stack_max > 1


## 检查是否是武器
func is_weapon() -> bool:
	return type == ItemType.WEAPON


## 检查是否是近战武器
func is_melee_weapon() -> bool:
	return type == ItemType.WEAPON and weapon_subtype == WeaponSubtype.MELEE


## 检查是否是远程武器
func is_ranged_weapon() -> bool:
	return type == ItemType.WEAPON and weapon_subtype == WeaponSubtype.RANGED


## 检查是否可消耗
func is_consumable() -> bool:
	return type in [ItemType.FOOD, ItemType.MEDICAL]


## 检查是否可购买
func is_purchasable() -> bool:
	return price >= 0


## 计算武器DPS
func get_weapon_dps() -> float:
	if not is_weapon():
		return 0.0
	return damage * attack_speed
