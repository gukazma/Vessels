# 三国 · 战术试验场

这是独立于旧项目的《英雄连》式三国小队战术原型。旧的丧尸生存项目仍在根目录运行；本项目从灰盒战场开始，不复用旧项目的玩法或美术。

## M0：指挥与移动

打开 `games/three_kingdoms/project.godot`，运行 `levels/command_sandbox.tscn`。

| 操作 | 输入 |
| --- | --- |
| 选择小队 | 左键点击 |
| 框选 | 按住左键拖拽 |
| 加选 / 取消单队 | Shift + 点击或框选 |
| 移动 | 右键 |
| 停止 | X |
| 聚焦选中部队 | F |
| 清除选择 | Esc |
| 重置场景 | R |
| 镜头平移 | WASD 或鼠标中键拖拽 |
| 镜头缩放 | 鼠标滚轮 |

当前每支小队包含一名带旗主将和六名士兵。右键命令由中心路径导航处理，会为编队预留 28 像素障碍距离，经过中央障碍后在目标附近分配间距。M0 暂不包含伤害、兵种、士气、资源、招募或攻城。

## 检查

```powershell
$godot = 'C:\Program Files\Godot\Godot.exe'
& $godot --headless --path games/three_kingdoms --script res://tests/navigation_test.gd
& $godot --headless --path games/three_kingdoms --fixed-fps 60 --script res://tests/command_test.gd -- --ticks=60
& $godot --headless --path games/three_kingdoms --fixed-fps 120 --script res://tests/command_test.gd -- --ticks=120
```

代码测试通过后仍需实际试玩。M0 的反馈重点是：选择是否清楚、移动是否有响应、绕障碍是否自然、队伍间距是否舒服、镜头速度是否合适。
