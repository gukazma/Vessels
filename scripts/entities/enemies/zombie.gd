# zombie.gd
# 僵尸 AI - 继承 Entity 基类
# 实现闲逛、追击、攻击三种状态
class_name Zombie
extends Entity

## ==================== 信号 ====================

## 发现玩家
signal player_detected(player: Node)

## 丢失玩家
signal player_lost()

## 攻击玩家
signal attacked(target: Node, damage: float)

## ==================== 枚举 ====================

enum ZombieState {
	IDLE,     ## 闲置
	WANDER,   ## 闲逛
	CHASE,    ## 追击
	ATTACK    ## 攻击
}

## ==================== 导出变量 ====================

## 僵尸类型
@export var zombie_type: String = "normal"

## 攻击伤害
@export var attack_damage: float = 15.0

## 攻击范围
@export var attack_range: float = 24.0

## 攻击冷却 (秒)
@export var attack_cooldown: float = 1.0

## 视野范围
@export var vision_range: float = 150.0

## 听力范围 (声音吸引)
@export var hearing_range: float = 200.0

## 追击速度倍率
@export var chase_speed_multiplier: float = 1.2

## 闲逛移动时间
@export var wander_time_min: float = 2.0
@export var wander_time_max: float = 5.0

## 闲置等待时间
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 3.0

## ==================== 状态变量 ====================

## 当前状态
var current_state: ZombieState = ZombieState.IDLE

## 目标玩家
var target_player: Node = null

## 攻击计时器
var attack_timer: float = 0.0

## 状态计时器
var state_timer: float = 0.0

## 闲逛方向
var wander_direction: Vector2 = Vector2.ZERO

## ==================== 节点引用 ====================

## 动画精灵节点
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

## 视野检测区域
@onready var vision_area: Area2D = $VisionArea if has_node("VisionArea") else null

## 攻击检测区域
@onready var attack_area: Area2D = $AttackArea if has_node("AttackArea") else null

## ==================== 生命周期 ====================

func _on_entity_ready() -> void:
	# 添加到敌人组
	add_to_group("enemies")
	add_to_group("zombies")

	# 设置检测区域
	_setup_detection_areas()

	# 初始化状态
	_change_state(ZombieState.IDLE)

	print("[Zombie] 僵尸已生成: %s" % zombie_type)


func _process(delta: float) -> void:
	if not is_alive:
		return

	# 更新攻击计时器
	if attack_timer > 0:
		attack_timer -= delta

	# 更新状态计时器
	state_timer -= delta

	# 更新动画
	_update_animation()


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# 根据状态处理行为
	match current_state:
		ZombieState.IDLE:
			_process_idle(delta)
		ZombieState.WANDER:
			_process_wander(delta)
		ZombieState.CHASE:
			_process_chase(delta)
		ZombieState.ATTACK:
			_process_attack(delta)


## ==================== 状态处理 ====================

func _process_idle(_delta: float) -> void:
	# 检查是否发现玩家
	if _check_for_player():
		return

	# 闲置时间结束，开始闲逛
	if state_timer <= 0:
		_change_state(ZombieState.WANDER)


func _process_wander(_delta: float) -> void:
	# 检查是否发现玩家
	if _check_for_player():
		return

	# 移动
	set_move_direction(wander_direction)

	# 闲逛时间结束
	if state_timer <= 0:
		_change_state(ZombieState.IDLE)


func _process_chase(_delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		_change_state(ZombieState.IDLE)
		player_lost.emit()
		return

	# 检查目标是否存活
	if target_player.has_method("get") and not target_player.is_alive:
		target_player = null
		_change_state(ZombieState.IDLE)
		return

	# 检查距离
	var distance = get_distance_to(target_player)

	if distance <= attack_range:
		# 进入攻击状态
		_change_state(ZombieState.ATTACK)
	elif distance > vision_range * 1.5:
		# 丢失目标
		target_player = null
		_change_state(ZombieState.IDLE)
		player_lost.emit()
	else:
		# 追击
		var direction = get_direction_to(target_player)
		set_move_direction(direction)


func _process_attack(_delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		_change_state(ZombieState.IDLE)
		return

	# 停止移动
	stop_moving()

	# 面向目标
	var direction = get_direction_to(target_player)
	facing_direction = direction

	# 检查距离
	var distance = get_distance_to(target_player)

	if distance > attack_range * 1.5:
		# 目标太远，继续追击
		_change_state(ZombieState.CHASE)
		return

	# 攻击
	if attack_timer <= 0:
		_perform_attack()
		attack_timer = attack_cooldown


func _change_state(new_state: ZombieState) -> void:
	var old_state = current_state
	current_state = new_state

	# 退出旧状态
	match old_state:
		ZombieState.CHASE:
			reset_speed_modifier()
		ZombieState.ATTACK:
			pass

	# 进入新状态
	match new_state:
		ZombieState.IDLE:
			stop_moving()
			state_timer = randf_range(idle_time_min, idle_time_max)

		ZombieState.WANDER:
			# 随机选择方向
			wander_direction = Vector2(
				randf_range(-1, 1),
				randf_range(-1, 1)
			).normalized()
			state_timer = randf_range(wander_time_min, wander_time_max)

		ZombieState.CHASE:
			set_speed_modifier(chase_speed_multiplier)

		ZombieState.ATTACK:
			stop_moving()


## ==================== 检测和攻击 ====================

func _check_for_player() -> bool:
	if target_player and is_instance_valid(target_player):
		return true

	# 查找范围内的玩家
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player is Node2D:
			var distance = global_position.distance_to(player.global_position)
			if distance <= vision_range:
				# 检查视线 (可以添加射线检测)
				target_player = player
				_change_state(ZombieState.CHASE)
				player_detected.emit(player)
				return true

	return false


func _perform_attack() -> void:
	if not target_player or not is_instance_valid(target_player):
		return

	# 造成伤害
	if target_player.has_method("take_damage"):
		target_player.take_damage(attack_damage, self)
		attacked.emit(target_player, attack_damage)

	# 通知事件总线
	if EventBus:
		EventBus.entity_damaged.emit(target_player, attack_damage, self)


func _setup_detection_areas() -> void:
	if vision_area:
		vision_area.body_entered.connect(_on_vision_body_entered)
		vision_area.body_exited.connect(_on_vision_body_exited)

	if attack_area:
		attack_area.body_entered.connect(_on_attack_body_entered)


func _on_vision_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_player = body
		_change_state(ZombieState.CHASE)
		player_detected.emit(body)


func _on_vision_body_exited(body: Node2D) -> void:
	if body == target_player:
		# 延迟丢失目标判定
		if current_state != ZombieState.ATTACK:
			await get_tree().create_timer(2.0).timeout
			if not _is_player_in_vision():
				target_player = null
				_change_state(ZombieState.IDLE)
				player_lost.emit()


func _on_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == ZombieState.CHASE:
		target_player = body
		_change_state(ZombieState.ATTACK)


func _is_player_in_vision() -> bool:
	if not target_player or not is_instance_valid(target_player):
		return false
	return get_distance_to(target_player) <= vision_range


## ==================== 声音吸引 ====================

## 被声音吸引
func attract_to_sound(sound_position: Vector2) -> void:
	if current_state == ZombieState.ATTACK:
		return

	var distance = global_position.distance_to(sound_position)
	if distance <= hearing_range:
		# 向声源移动
		wander_direction = (sound_position - global_position).normalized()
		_change_state(ZombieState.WANDER)
		state_timer = distance / move_speed  # 移动到声源的时间


## ==================== 动画更新 ====================

func _update_animation() -> void:
	if not animated_sprite:
		return

	var anim_name = ""

	match current_state:
		ZombieState.IDLE:
			anim_name = "idle"
		ZombieState.WANDER:
			anim_name = "walk"
		ZombieState.CHASE:
			anim_name = "walk"  # 或 "run"
		ZombieState.ATTACK:
			anim_name = "attack"

	# 播放动画
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)

	# 水平翻转精灵
	if facing_direction.x != 0:
		animated_sprite.flip_h = facing_direction.x < 0


## ==================== 重写基类方法 ====================

func _on_death() -> void:
	super._on_death()

	# 停止所有行动
	current_state = ZombieState.IDLE
	stop_moving()

	# 播放死亡动画
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("death"):
			animated_sprite.play("death")

	# 通知事件总线
	if EventBus:
		EventBus.zombie_killed.emit(global_position, zombie_type)

	print("[Zombie] 僵尸死亡")


## ==================== 公共方法 ====================

## 获取当前状态名
func get_state_name() -> String:
	match current_state:
		ZombieState.IDLE:
			return "idle"
		ZombieState.WANDER:
			return "wander"
		ZombieState.CHASE:
			return "chase"
		ZombieState.ATTACK:
			return "attack"
		_:
			return "unknown"


## 强制设置目标
func set_target(target: Node) -> void:
	target_player = target
	if target:
		_change_state(ZombieState.CHASE)


## ==================== 存档相关 ====================

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["zombie_type"] = zombie_type
	data["current_state"] = current_state
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	zombie_type = data.get("zombie_type", "normal")
	_change_state(data.get("current_state", ZombieState.IDLE))
