extends Node

## 截图管理器 - 让 AI 能够"看到"游戏画面
## F12: 手动截图
## 自动截图: 每隔一定时间自动保存截图

@export var auto_screenshot_enabled: bool = true
@export var auto_screenshot_interval: float = 3.0  # 秒

var screenshot_timer: float = 0.0
var screenshot_dir: String = "res://screenshots/"
var screenshot_count: int = 0
const MAX_SCREENSHOTS: int = 5  # 保留最近的截图数量

func _ready() -> void:
	# 创建截图目录
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
	print("[ScreenshotManager] 截图系统已启动")
	print("[ScreenshotManager] F12 手动截图 | 自动截图间隔: ", auto_screenshot_interval, "秒")

func _process(delta: float) -> void:
	# 自动截图
	if auto_screenshot_enabled:
		screenshot_timer += delta
		if screenshot_timer >= auto_screenshot_interval:
			screenshot_timer = 0.0
			take_screenshot("auto")

func _input(event: InputEvent) -> void:
	# F12 手动截图
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		take_screenshot("manual")

func take_screenshot(prefix: String = "screenshot") -> void:
	# 等待当前帧渲染完成
	await RenderingServer.frame_post_draw

	# 获取视口图像
	var viewport = get_viewport()
	var image = viewport.get_texture().get_image()

	# 生成文件名 (使用固定名称便于 AI 读取)
	var filename: String
	if prefix == "auto":
		# 自动截图使用循环命名
		filename = screenshot_dir + "latest.png"
	else:
		# 手动截图带时间戳
		var time = Time.get_datetime_dict_from_system()
		filename = screenshot_dir + "%s_%04d%02d%02d_%02d%02d%02d.png" % [
			prefix, time.year, time.month, time.day,
			time.hour, time.minute, time.second
		]

	# 保存图像
	var error = image.save_png(filename)
	if error == OK:
		print("[ScreenshotManager] 截图已保存: ", filename)
	else:
		print("[ScreenshotManager] 截图保存失败: ", error)
