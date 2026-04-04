# ── NodeStateMachine ─────────────────────────────────────────
# 状态机管理器，作为父节点管理所有 NodeState 子节点
#
# 使用方式：
# 1. 在场景中添加 NodeStateMachine 节点
# 2. 在它下面添加各个状态节点（Idle、Walk 等），脚本继承 NodeState
# 3. 在编辑器里把初始状态节点拖到 initial_node_state 属性
# 4. 运行时状态机自动接管，通过 transition 信号切换状态
# ─────────────────────────────────────────────────────────────
class_name NodeStateMachine
extends Node

# 初始状态的节点名称（字符串，不依赖 NodePath 解析）
@export var initial_state_name: String = "Idle"

# 状态字典：key=状态节点名小写, value=NodeState节点
# 例：{ "idle": <Idle节点>, "walk": <Walk节点> }
var node_states: Dictionary = {}
var current_node_state: NodeState
var current_node_state_name: String
var parent_node_name: String  # 用于日志输出，方便调试多个状态机


func _ready() -> void:
	parent_node_name = get_parent().name

	# 自动扫描所有 NodeState 子节点并注册
	# 这样新增状态只需在场景里加节点，不需要修改这里的代码
	for child in get_children():
		if child is NodeState:
			node_states[child.name.to_lower()] = child
			# 监听每个状态的 transition 信号
			child.transition.connect(transition_to)

	# 按名字找到初始状态并启动
	var initial = node_states.get(initial_state_name.to_lower())
	if initial:
		initial._on_enter()
		current_node_state = initial
		current_node_state_name = current_node_state.name.to_lower()
	else:
		push_error("[NodeStateMachine] 找不到初始状态: " + initial_state_name)


func _process(delta: float) -> void:
	if current_node_state:
		current_node_state._on_process(delta)


func _physics_process(delta: float) -> void:
	if current_node_state:
		current_node_state._on_physics_process(delta)
		# 物理逻辑之后再检查切换条件，顺序很重要：
		# 先更新位置，再判断下一帧该进入哪个状态
		current_node_state._on_next_transitions()


# 执行状态切换
# 由各状态通过 transition.emit("目标状态名") 触发
func transition_to(node_state_name: String) -> void:
	# 目标状态就是当前状态，忽略（防止重复切换）
	if node_state_name == current_node_state.name.to_lower():
		return

	var new_node_state = node_states.get(node_state_name.to_lower())
	if !new_node_state:
		push_warning("[NodeStateMachine] 找不到状态: " + node_state_name)
		return

	# 退出当前状态 → 进入新状态
	if current_node_state:
		current_node_state._on_exit()

	new_node_state._on_enter()
	current_node_state = new_node_state
	current_node_state_name = current_node_state.name.to_lower()
	print("[%s] → %s" % [parent_node_name, current_node_state_name])
