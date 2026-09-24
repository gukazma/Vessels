# Vessels · 像素丧尸生存原型

当前版本为 **明亮、精致的 2D 俯视角像素小镇**：四方向幸存者、日光街区、碰撞移动、12 格背包、物品拾取和三种武器。已接入血量、医疗包及可受伤的训练靶；暂未加入丧尸 AI 和存档。背包与场景状态只保留在本次运行中。

## 运行与操作

用 **Godot 4.6.1 标准版**打开根目录 `project.godot`，等待导入完成，按 **F5**。

| 操作 | 按键 |
| --- | --- |
| 八方向移动 | WASD |
| 奔跑 | 按住左 Shift |
| 朝当前方向短冲刺 | 空格 |
| 拾取最近的可见物资 | E |
| 打开 / 关闭背包 | B 或 Tab |
| 瞄准 / 攻击 | 鼠标移动 / 左键单击 |
| 换弹 | R |
| 撬棍 / 手枪 / 霰弹枪 | 1 / 2 / 3（需要已持有） |
| 暂停 / 继续 | Esc |

持武器时，人物朝向跟随鼠标，可侧移和倒退；冲刺仍沿当前或最后的移动方向。冲刺有冷却时间，右下角显示恢复进度；冲刺不能穿墙，也没有无敌帧。切到其他应用会自动暂停，回来按 Esc 继续。鼠标不再锁定。

## 背包与武器试玩

1. 开局装备撬棍，背包内带一个医疗包。出生点左下方就是装有 8 发子弹的手枪，原地按 **E** 即可拾取，再按 **2** 装备。
2. 朝训练靶移动鼠标，单击左键攻击。手枪弹药在附近，空弹匣时按 **R** 从背包补充。
3. 沿道路往右下走可找到霰弹枪和霰弹。按 **3** 切换后，每次射击消耗一发霰弹、发出五颗弹丸。
4. 按 **B** 查看 12 格背包，选中物品后点击 **EQUIP WEAPON / USE / DROP STACK**。打开背包会暂停世界；Esc 优先关闭背包。

| 武器 | 伤害 | 弹匣 | 射程 | 换弹 |
| --- | --- | --- | --- | --- |
| 撬棍 | 28 | 无 | 36 px 近战范围 | 无 |
| 手枪 | 24 | 8 | 300 px | 0.9 秒 |
| 霰弹枪 | 每颗 12，共 5 颗 | 2 | 170 px | 1.25 秒 |

射击使用即时射线，近战使用前方范围检测，两者都会被世界墙体挡住。弹道、枪口闪光、近战挥动、靶子闪烁和血条提供反馈。训练靶被击倒后 3 秒恢复，方便反复验证攻击。

弹药自动堆叠（9mm 每格 60 发、霰弹每格 20 发），医疗包每格 5 个。满包时只拾取能容纳的数量，剩余物资留在地上。丢弃的是整组物品；每把枪的弹匣独立保存，切换、丢弃再拾取都不会重置子弹。切枪取消换弹，备用弹药仅在换弹完成时扣除。

医疗包最多恢复 40 HP，满血时不会消耗。当前训练靶不会攻击玩家，回血逻辑已测试，供后续丧尸攻击接入。

## 像素表现

- 美术采用温暖日光、陶瓦与青绿色屋顶、奶油色墙面、砂岩步道和分层绿植；封锁设施与旧车辆保留故事背景。
- 诊所与商店分别拥有百叶窗、条纹遮阳篷、玻璃反光和花箱；新增长椅、邮箱、花坛及少量蝴蝶，物品带有落地阴影与收纳布。
- 人物重绘为青蓝外套、金色围巾和背包；纸色 HUD 与背包使用深青文字、鼠尾草绿和陶土橙，减少对场景的遮挡。
- 真正的 CharacterBody2D、Sprite2D、Camera2D 场景，采用 640 × 360 内部分辨率。
- 默认以 1280 × 720 窗口运行，整数倍放大、最近邻采样与像素吸附保持清晰；不匹配整数比例的窗口允许留黑边。
- 角色支持四方向待机/行走，八方向移动；步态跟随实际位移，顶着墙不会原地快跑。
- 道具与角色使用 Y 排序，人物可走到树木和建筑背后；脚部碰撞与高处图像独立。
- 场景、角色与物品使用本地绘制脚本生成的原创 PNG。场景中的建筑、车辆、树木、路障和碰撞体都是可直接编辑的独立 Godot 节点。

## 工程结构

```text
project.godot              当前 2D 项目入口
features/player/          主角场景、移动、输入、四方向动画
features/inventory/       背包数据、独立物品堆栈与背包界面
features/items/           物品定义、目录、拾取和丢弃交互
features/weapons/         装备、弹匣、换弹、射击和近战
features/combat/          血量组件、可受伤的训练靶
features/hud/             操作提示、弹药、血量、提示、小地图和暂停
features/environment/     独立环境表现（花坛上方的蝴蝶）
data/items/               可在 Inspector 编辑的物品和武器 .tres 数据
levels/                   街区、独立物资/训练靶场景和边界恢复
assets/pixel/             PNG 素材、导入配置及素材规范
tools/pixel/              可重复生成的像素绘制脚本
tools/check.ps1           一键检查
tools/capture_preview.gd  实际渲染截图
tests/                    移动、背包、拾取与战斗集成测试
archive/3d/               之前的完整 3D 原型与 Blender 源模型
```

`archive/.gdignore` 防止旧版类名与资源进入当前工程。需要回看旧版时，可单独在 Godot 导入 `archive/3d/project.godot`。`.godot/` 缓存与日志不提交；PNG、导入配置及 `.gd.uid` 应保留在版本管理中。

## 代码质量与调参

- `player_controller.gd` 使用有类型的 GDScript，只接收移动向量和冲刺请求；物理帧内执行加减速、冷却和碰撞。
- `player_input.gd` 专门采样 Input Map，在控制器之前运行；对角线输入归一化，不会比直线更快。
- `survivor_visual.gd` 只负责精灵方向与逐帧动画，可替换素材而不影响移动逻辑。
- HUD 拥有暂停行为；暂停或窗口失焦会清除待执行的移动，避免恢复时滑动。
- 世界边界和异常位置恢复属于关卡，不写入通用角色脚本。
- `inventory.gd` 独占物品数量与弹匣的修改；读取槽位返回快照，避免界面意外修改数据。一次变更只发出一次通知。
- `weapon_controller.gd` 负责攻击间隔、装备与换弹，武器数值来自 `data/items/`；每把枪的已装子弹保存在物品堆栈中。
- `weapon_visual.gd` 独立负责手部握点、前后遮挡、后坐力和挥动。枪械使用举臂人物图，前后朝向切换到轴向枪管视图；腿部行走不会让举枪手臂左右摆动。持握素材与背包图标分开；武器作为身体精灵的子节点参与角色内部遮挡，保持整个人物的世界 Y 排序。
- `item_interactor.gd` 负责拾取距离、视线遮挡、安全丢弃位置和消耗医疗包；`inventory/ui/` 只呈现物品并调用这些操作。
- `levels/supply_demo.tscn` 独立放置物资与训练靶；重新生成基础街道不会覆盖这部分布局。
- 素材工具按职责拆分：`environment_art.py` 绘制场景，`survivor_art.py` 绘制角色，`build_items.py` 绘制物品；`build_assets.py` 组织重建并生成关卡节点。`pixel_common.py` 提供共享绘制和标牌文字工具。

选中主角根节点，可在 Inspector 调整步行速度（86 像素/秒）、奔跑速度（140）、加速度、刹车和冲刺。World 使用第 1 碰撞层，Player 第 2 层，Damageable 第 3 层，Pickup 第 4 层。按键配置在 Project Settings → Input Map。

## 素材制作与插件

**运行游戏不需要任何额外插件，也不需要 Python 或 Blender。** Godot 内置功能足够完成当前 2D 原型。

像素图可以用 Aseprite 或免费的 Pixelorama 精修，它们是可选的绘图工具。Blender 的旧模型已保存在 `archive/3d/art/blender/survivor.blend`，以后也能用于离线渲染像素角色的参考或序列帧。

素材流程：编辑 PNG → Godot 自动重新导入 → 在场景中调整道具和碰撞。角色图集与坐标约定见 `assets/pixel/README.md`。

若要重建脚本生成的初始素材：

```powershell
python -m pip install -r tools/pixel/requirements.txt
python tools/pixel/build_assets.py
python tools/pixel/build_items.py
python tools/pixel/build_held_weapons.py
```

该命令会覆盖生成的 PNG 和 `levels/quarantine_street.tscn`。自己手工编辑过素材或场景时，应先保存版本，再决定是否重新生成。

## 验证

```powershell
powershell -ExecutionPolicy Bypass -File tools/check.ps1
```

Godot 不在 PATH 时，追加 `-Godot 'C:\Program Files\Godot\Godot.exe'`。

检查导入、主场景启动，以及 **60 Hz / 120 Hz 各 137 项**运行测试（移动 30 项，背包与战斗 42 项，武器表现 65 项）。检查包含堆叠与容量、部分拾取、独立弹匣、切枪取消换弹、子弹消耗、射击/近战墙体遮挡、霰弹弹丸、丢弃再拾取、医疗包，以及背包暂停和按钮操作。武器表现覆盖八方向握点、后退瞄准与冲刺兼容、挥动和后坐力、举枪步态、枪械视角、同帧转身开火的枪口位置，以及换装时清理动画。日志保存在 `.godot/`，不依赖第三方测试插件。

实际渲染截图：

```powershell
godot --path . --script res://tools/capture_preview.gd
godot --path . --script res://tools/capture_preview.gd -- --inventory
godot --path . --script res://tools/capture_preview.gd -- --paused
godot --path . --script res://tools/capture_preview.gd -- --aiming
godot --path . --script res://tools/capture_weapon_poses.gd
```

结果位于 `.godot/pixel-preview.png`、`.godot/inventory-preview.png` 和 `.godot/pause-preview.png`。背包截图会在预览进程中收集场景物资以展示界面；正常游戏仍需自行拾取。自动测试验证行为，手感和美术风格仍应通过试玩决定。

武器截图工具需要真实渲染器（不能使用 `--headless`），生成 `.godot/weapon-poses.png`、`weapon-attacks.png`、`weapon-walk.png`、`weapon-occlusion.png`，并比较实际像素验证背身/正面遮挡及场景 Y 排序，失败时返回非零退出码。`--aiming` 预览在街区中展示背身举枪，输出 `.godot/aiming-preview.png`。

## 下一阶段

下一步可把已验证的伤害接口接到丧尸，加入巡逻 → 发现 → 追逐 → 攻击，再实现死亡处理、音效与存档。
