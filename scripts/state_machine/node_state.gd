# ── NodeState ────────────────────────────────────────────────
# 所有具体状态的基类（Idle、Walk、Chopping 等都继承它）
#
# 状态机的核心思想：
# 把角色的每种"行为"封装成独立的 Node 子节点
# 每个状态只关心自己的逻辑，不需要知道其他状态的存在
# 切换状态时发出 transition 信号，由 NodeStateMachine 统一处理
# ─────────────────────────────────────────────────────────────
class_name NodeState
extends Node

# 状态切换信号
# 用法：transition.emit("Walk")  →  请求切换到名为 "Walk" 的状态
# NodeStateMachine 监听这个信号并执行实际的切换
@warning_ignore("unused_signal")
signal transition


# ── 生命周期钩子（子类按需重写）────────────────────────────────

func _on_process(_delta: float) -> void:
	pass  # 每帧调用（适合 UI 更新、计时器等非物理逻辑）

func _on_physics_process(_delta: float) -> void:
	pass  # 每物理帧调用（适合移动、速度更新）

func _on_next_transitions() -> void:
	pass  # 每物理帧检查是否需要切换状态（在 physics_process 之后调用）
	      # 把切换检查和物理逻辑分开，代码更清晰

func _on_enter() -> void:
	pass  # 进入此状态时调用一次（播放进入动画、重置变量等）

func _on_exit() -> void:
	pass  # 离开此状态时调用一次（停止动画、清理资源等）
