# Vessels · 丧尸生存原型

第一阶段：3D 第三人称主角移动。包含 Blender 原创低多边形幸存者和隔离区测试场地，尚未实现丧尸 AI、战斗或背包系统。

## 立即运行

1. 用 **Godot 4.6.1 标准版**导入本目录的 `project.godot`。
2. 等待素材导入完成，按 **F6** 运行当前场景，或按 **F5** 运行整个项目。推荐直接 F5。
3. WASD 移动、左 Shift 冲刺、空格跳跃、鼠标转动镜头；Esc 释放鼠标，单击游戏画面恢复控制。切换到其他应用时也会自动释放鼠标。

地面的 `01 / INCLINE` 是坡道，`02 / JUMP` 是跳跃障碍。角色掉出场地后会返回出生点。角色不会自动跨台阶，需要跳过障碍。

## 要安装什么

| 工具 / 插件 | 是否需要 | 用途 |
| --- | --- | --- |
| Godot 4.6.x 标准版 | 必需，本机已有 4.6.1 | GDScript 编程、场景编辑、运行游戏，无需 .NET |
| Blender | 修改素材时需要，本机使用 5.2.2 LTS | 建模及导出 GLB |
| 额外 Godot / Blender 插件 | 当前不需要 | 碰撞、第三人称镜头、glTF 导入导出均使用内置功能 |
| Git | 建议，当前目录已经是仓库 | 保存代码和素材版本 |

无需 MCP、第三人称控制器插件或复杂状态机即可迭代本原型。后续大量二进制素材可以再引入 Git LFS；正式人物动画可使用 Blender 骨架和 Godot AnimationTree。

## 工程目录

```text
project.godot          项目入口和输入映射
features/
  player/             主角场景、移动、输入、镜头、人物表现
  hud/                操作提示和速度显示
levels/
  movement_yard.*     隔离区测试场地与掉落恢复
  props/              可复用的碰撞物件
assets/characters/    Godot 使用的 GLB
art/blender/          Blender 原始工程，不由 Godot 导入
tools/                素材生成、检查和截图工具，不自动导入
tests/                真实物理运行集成测试
```

`.godot/` 是缓存及检查日志，不提交；`.blend`、`.glb`、`.glb.import` 和 `.gd.uid` 应提交。`art/.gdignore` 避免 Godot 自动调用 Blender 重复导入源文件。

## 代码约定与职责

- `player_controller.gd`：只接收世界坐标方向、冲刺和跳跃请求，使用 CharacterBody3D 实现重力、加减速、坡面吸附和碰撞滑动。
- `player_input.gd`：读取 Input Map，将 WASD 转为相对镜头的方向；处理鼠标捕获与窗口失焦。优先于角色执行物理输入采样。
- `third_person_camera.gd`：水平旋转、俯仰限制及 SpringArm3D 镜头避障。角色身体旋转不会带着镜头旋转。
- `survivor_visual.gd`：人物转向之外的步态表现，使用 Blender 模型的四肢枢轴。当前是程序化摆动，不是骨骼动画；后续可替换为 AnimationTree。
- `movement_yard.gd`：仅负责关卡内的掉落恢复，角色可以单独复用到其他关卡。

使用有类型的 GDScript。移动在固定物理帧内执行，速度使用米/秒，不将速度重复乘以 delta。输入向量限制长度，斜向不会更快。暂不添加全局单例、空管理器或没有需求的抽象层。

选中主角根节点，可在 Inspector 调整步行速度（4.2）、冲刺速度（7.2）、加速度、刹车速度、跳跃速度和空中控制。镜头参数在 `CameraRig` 上；按键在 Project Settings → Input Map 中修改。World 使用第 1 碰撞层，Player 使用第 2 层。

## Blender → Godot 素材流程

1. 打开 `art/blender/survivor.blend` 修改模型。单位为米；Blender 中 +Y 是人物正前方，导出后对应 Godot 的 -Z。
2. File → Export → glTF 2.0，选择 **GLB**，开启默认的 **+Y Up**，导出到 `assets/characters/survivor.glb`。
3. 保留 `ArmLeftPivot`、`ArmRightPivot`、`LegLeftPivot`、`LegRightPivot` 四个枢轴名称，当前步态脚本依赖它们。正式更换骨架时应一起替换表现脚本。
4. Godot 自动重新导入，玩家场景中的胶囊碰撞体与模型独立。

也可从脚本重建初始模型（会覆盖当前 `.blend` 和 `.glb`，因此自己修改过的模型应先保存版本）：

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python tools/blender/build_survivor.py
```

## 质量检查

在项目目录运行，不依赖第三方测试框架：

```powershell
powershell -ExecutionPolicy Bypass -File tools/check.ps1
```

如果 Godot 不在 PATH 中，传入 `-Godot 'C:\Program Files\Godot\Godot.exe'`。

检查包含资源导入、主场景启动，以及 **60 Hz / 120 Hz 各 25 项物理检查**：速度与位移、斜向归一化、冲刺与刹车、跳跃与禁止二段跳、墙体阻挡与滑动、坡道上下行、镜头方向与角度限制、镜头避障与恢复、释放鼠标停止输入、实际关卡出生/坡道/掉落恢复。日志位于 `.godot/`。

截图工具需要图形渲染环境：

```powershell
godot --path . --script res://tools/capture_preview.gd
```

截图生成于 `.godot/movement-preview.png`。自动测试之外，仍建议亲自试玩确认鼠标灵敏度、跳跃节奏和模型动作是否符合预期。

## 推荐下一阶段

先确定镜头距离与移动手感，再实现一只丧尸的巡逻、发现、追逐和近距离攻击；随后接入角色生命值与受击反馈，最后扩展武器、物品交互和存档。
