# Vessels 项目 - AI 自动化游戏开发指南

## 项目概述
这是一个像素风格游戏项目，配备了完整的 AI 自动化开发和测试系统。

## MCP 工具配置

### Aseprite MCP
- 用于绘制像素精灵和动画
- 通过 Lua 脚本自动创建美术资源
- 路径: `C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe`

### Godot MCP
- 用于操控 Godot 引擎
- 支持运行项目、获取调试输出、停止项目等
- 路径: `C:\Program Files\Godot\Godot.exe`

## 全自动开发流程

### 1. 美术资源制作 (Aseprite)
```bash
# 创建 Lua 脚本绘制精灵
Write assets/scripts/draw_xxx.lua

# 执行脚本生成 .aseprite 文件
Aseprite.exe -b --script "脚本路径"

# 导出为 PNG 精灵表
aseprite_export_sheet(inputFile, outputSheet, dataFile)
```

### 2. 资源导入 (Godot Headless)
```bash
# 自动导入资源，无需打开编辑器 GUI
Godot.exe --headless --import --path "项目路径"
```

### 3. 场景和脚本编写
- 直接编辑 .tscn 场景文件
- 直接编辑 .gd 脚本文件
- 使用 Godot MCP 的 create_scene, add_node 等工具

### 4. 运行和测试
```bash
# 启动游戏
mcp__godot-mcp__run_project(projectPath)

# 等待测试完成
sleep 10-15 秒

# 获取调试输出和测试结果
mcp__godot-mcp__get_debug_output()

# 查看截图验证视觉效果
Read screenshots/latest.png
Read screenshots/test_*.png

# 停止游戏
mcp__godot-mcp__stop_project()
```

## 内置系统

### 截图管理器 (screenshot_manager.gd)
- 每 3 秒自动保存 `screenshots/latest.png`
- F12 手动截图
- AI 通过读取截图"看到"游戏画面

### 自动测试系统 (auto_test.gd)
- 启动时自动执行测试序列
- 模拟玩家输入 (移动、停止等)
- 验证游戏逻辑 (位置变化、速度等)
- 生成测试报告

## 开发新功能的标准流程

1. **需求分析** - 理解要做什么
2. **美术制作** - 用 Aseprite Lua 脚本创建精灵
3. **导出资源** - 导出 PNG 精灵表
4. **导入 Godot** - `--headless --import` 自动导入
5. **编写场景/脚本** - 创建 .tscn 和 .gd 文件
6. **更新测试** - 在 auto_test.gd 中添加新测试用例
7. **运行验证** - 启动游戏，等待测试完成
8. **查看结果** - 读取调试输出和截图
9. **修复问题** - 根据测试结果修复 bug
10. **重复测试** - 直到所有测试通过

## 重要提示

- **始终自动执行**：不需要用户手动操作
- **截图验证**：每次修改后查看截图确认效果
- **测试驱动**：添加新功能时同步添加测试
- **调试输出**：通过 get_debug_output 获取日志
- **资源导入**：修改资源后必须重新执行 headless import

## 项目结构

```
Vessels/
├── project.godot           # Godot 项目配置
├── .mcp.json               # MCP 服务器配置
├── CLAUDE.md               # 本文件 - AI 开发指南
├── assets/
│   ├── scripts/            # Aseprite Lua 脚本
│   └── sprites/            # 精灵图片和动画
├── scenes/                 # Godot 场景文件
├── scripts/                # GDScript 脚本
│   ├── player.gd           # 玩家控制
│   ├── tree.gd             # 树动画
│   ├── screenshot_manager.gd # 截图系统
│   └── auto_test.gd        # 自动测试系统
└── screenshots/            # 测试截图输出
```

---

# 多子代理并行开发架构

## 架构概览

```
┌─────────────────────────────────────────────────────────────────┐
│                      主代理 (Coordinator)                        │
│                   只负责需求分析和任务分发                         │
│                      保持上下文干净                               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ 分发任务
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        设计层 (Design Layer)                     │
│  ┌─────────────────┐              ┌─────────────────┐           │
│  │ Game Designer   │              │ System Architect│           │
│  │ 游戏设计师       │─────────────▶│ 系统架构师       │           │
│  │ 剧情/玩法/关卡   │  设计需求    │ 框架/系统/模式   │           │
│  └─────────────────┘              └─────────────────┘           │
│           │                                │                    │
│           │ 设计文档                       │ 架构规范            │
│           ▼                                ▼                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ 指导实现
                                ▼
    ┌───────────────────────────────────────────────────────┐
    │                     实现层 (Implementation Layer)      │
    │                                                       │
    ▼                   ▼                   ▼               ▼
┌─────────┐      ┌─────────┐      ┌─────────┐      ┌─────────┐
│ Art     │      │ Scene   │      │ Script  │      │ Test    │
│ Agent   │      │ Agent   │      │ Agent   │      │ Agent   │
│         │      │         │      │         │      │         │
│ 美术    │      │ 场景    │      │ 脚本    │      │ 测试    │
│ worktree│      │ worktree│      │ worktree│      │ 主分支  │
│ /art    │      │ /scene  │      │ /script │      │ /main   │
└─────────┘      └─────────┘      └─────────┘      └─────────┘
    │                   │                   │               │
    └───────────────────┴───────────────────┘               │
                        │                                   │
                        ▼                                   │
              ┌─────────────────┐                          │
              │ Integration     │◄─────────────────────────┘
              │ Agent           │
              │ 集成合并        │
              └─────────────────┘
```

## 子代理定义

### 设计层代理

#### 0. Game Designer Agent (游戏设计代理)
**职责**: 设计游戏剧情、玩法机制、关卡设计、数值平衡
**工具**: Write, Read, WebSearch (参考设计)
**输出**: `docs/design/` 目录下的设计文档
**无 Worktree**: 纯文档输出，不涉及代码冲突

```
prompt: |
  你是游戏设计代理，专门负责游戏创意和玩法设计。

  职责范围:
  - 游戏剧情和世界观设定
  - 玩法机制设计 (战斗、探索、交互等)
  - 关卡设计和难度曲线
  - 数值平衡 (属性、伤害、经济系统)
  - 游戏体验和节奏把控

  工作流程:
  1. 分析用户需求，理解游戏愿景
  2. 输出设计文档到 docs/design/
     - story.md: 剧情大纲和世界观
     - mechanics.md: 核心玩法机制
     - levels.md: 关卡设计
     - balance.md: 数值设计
  3. 为其他代理提供设计指导

  输出格式:
  - 清晰的文档结构
  - 具体的实现建议
  - 可量化的数值参数

  示例输出 (背包系统):
  ```markdown
  # 背包系统设计

  ## 核心功能
  - 格子数量: 初始20格，可扩展到50格
  - 物品堆叠: 消耗品最多99个，装备不可堆叠
  - 分类标签: 全部/装备/消耗品/材料/任务物品

  ## 交互设计
  - 拖拽排序
  - 右键使用/装备
  - 双击快速使用
  - 长按显示详情

  ## 数据结构建议
  - item_id: String
  - quantity: int
  - slot_index: int
  ```
```

#### 0.1 System Architect Agent (系统架构师代理)
**职责**: 设计游戏底层框架、代码架构、系统模块
**工具**: Write, Read, Grep, Edit
**输出**: `docs/architecture/` 架构文档 + `scripts/core/` 核心框架代码
**分支**: `feature/arch-*`
**Worktree**: `.worktrees/arch`

```
prompt: |
  你是系统架构师代理，专门负责游戏底层框架设计和核心系统实现。

  职责范围:
  - 代码架构设计 (目录结构、模块划分)
  - 核心系统框架 (事件系统、状态机、对象池等)
  - 游戏系统设计 (背包、技能、任务、对话等)
  - 数据管理 (存档、配置、资源加载)
  - 设计模式应用 (单例、观察者、命令模式等)

  工作流程:
  1. 阅读 Game Designer 的设计文档
  2. 输出架构文档到 docs/architecture/
     - overview.md: 架构总览
     - systems.md: 系统模块设计
     - patterns.md: 设计模式说明
  3. 实现核心框架代码到 scripts/core/
  4. 为 Script Agent 提供基类和接口

  代码架构规范:
  ```
  scripts/
  ├── core/                    # 核心框架 (架构师负责)
  │   ├── autoload/           # 全局单例
  │   │   ├── game_manager.gd # 游戏状态管理
  │   │   ├── event_bus.gd    # 全局事件总线
  │   │   ├── save_manager.gd # 存档管理
  │   │   └── audio_manager.gd# 音频管理
  │   ├── base/               # 基类
  │   │   ├── state_machine.gd# 状态机基类
  │   │   ├── interactable.gd # 可交互物基类
  │   │   └── entity.gd       # 实体基类
  │   └── systems/            # 游戏系统
  │       ├── inventory/      # 背包系统
  │       ├── dialogue/       # 对话系统
  │       ├── quest/          # 任务系统
  │       └── skill/          # 技能系统
  ├── entities/               # 游戏实体 (Script Agent 负责)
  │   ├── player/
  │   ├── enemies/
  │   └── npcs/
  └── ui/                     # UI脚本
  ```

  设计模式示例:

  # 事件总线 (观察者模式)
  ```gdscript
  # scripts/core/autoload/event_bus.gd
  extends Node

  signal player_damaged(amount: int)
  signal item_collected(item_id: String)
  signal quest_completed(quest_id: String)
  signal game_state_changed(new_state: String)

  func emit_player_damaged(amount: int) -> void:
      player_damaged.emit(amount)
  ```

  # 状态机基类
  ```gdscript
  # scripts/core/base/state_machine.gd
  class_name StateMachine extends Node

  var current_state: State
  var states: Dictionary = {}

  func change_state(state_name: String) -> void:
      if current_state:
          current_state.exit()
      current_state = states.get(state_name)
      if current_state:
          current_state.enter()
  ```

  完成后提交到 feature/arch-{功能名} 分支
```

---

### 实现层代理

### 1. Art Agent (美术代理)
**职责**: 创建像素精灵和动画
**工具**: Aseprite MCP, Bash
**分支**: `feature/art-*`
**Worktree**: `.worktrees/art`

```
prompt: |
  你是美术代理，专门负责用 Aseprite 创建像素精灵。

  工作流程:
  1. 在 assets/scripts/ 创建 Lua 绘图脚本
  2. 执行: Aseprite.exe -b --script "脚本路径"
  3. 导出精灵表: aseprite_export_sheet()
  4. 返回创建的文件列表

  完成后提交到 feature/art-{功能名} 分支
```

### 2. Scene Agent (场景代理)
**职责**: 创建和编辑 Godot 场景
**工具**: Write, Edit, Godot MCP
**分支**: `feature/scene-*`
**Worktree**: `.worktrees/scene`

```
prompt: |
  你是场景代理，专门负责创建 Godot 场景文件。

  工作流程:
  1. 创建/编辑 scenes/*.tscn 文件
  2. 配置节点层级和属性
  3. 引用精灵资源
  4. 返回修改的场景列表

  完成后提交到 feature/scene-{功能名} 分支
```

### 3. Script Agent (脚本代理)
**职责**: 编写 GDScript 游戏逻辑
**工具**: Write, Edit, Grep
**分支**: `feature/script-*`
**Worktree**: `.worktrees/script`

```
prompt: |
  你是脚本代理，专门负责编写 GDScript。

  工作流程:
  1. 创建/编辑 scripts/*.gd 文件
  2. 实现游戏逻辑
  3. 添加测试用例到 auto_test.gd
  4. 返回修改的脚本列表

  完成后提交到 feature/script-{功能名} 分支
```

### 4. Test Agent (测试代理)
**职责**: 运行游戏、执行测试、验证结果
**工具**: Godot MCP, Read, Bash
**分支**: `main` (只读验证)

```
prompt: |
  你是测试代理，专门负责验证游戏功能。

  工作流程:
  1. 执行 headless import: Godot.exe --headless --import
  2. 运行项目: mcp__godot-mcp__run_project()
  3. 等待测试: sleep 15
  4. 获取结果: mcp__godot-mcp__get_debug_output()
  5. 查看截图: Read screenshots/latest.png
  6. 停止项目: mcp__godot-mcp__stop_project()
  7. 返回测试报告 (通过/失败/截图)
```

### 5. Integration Agent (集成代理)
**职责**: 合并分支、解决冲突
**工具**: Bash (git), Read, Edit
**分支**: `main`

```
prompt: |
  你是集成代理，专门负责代码合并。

  工作流程:
  1. 检查所有 feature/* 分支状态
  2. 按顺序合并: art -> scene -> script
  3. 解决冲突 (如有)
  4. 执行最终测试
  5. 返回合并结果
```

## Git Worktree 设置

### 初始化 Worktrees
```bash
# 在项目根目录执行
git worktree add .worktrees/arch -b feature/arch-current   # 架构师代理
git worktree add .worktrees/art -b feature/art-current     # 美术代理
git worktree add .worktrees/scene -b feature/scene-current # 场景代理
git worktree add .worktrees/script -b feature/script-current # 脚本代理
```

### Worktree 目录结构
```
Vessels/                    # 主工作目录 (main 分支)
├── .worktrees/
│   ├── arch/              # 架构师代理工作目录
│   ├── art/               # 美术代理工作目录
│   ├── scene/             # 场景代理工作目录
│   └── script/            # 脚本代理工作目录
```

## 主代理工作流程

当用户提出需求时，主代理按以下步骤执行:

### 1. 需求分析
```
解析用户需求，拆分为:
- 设计任务 (需要什么玩法/剧情设计)
- 架构任务 (需要什么系统框架)
- 美术任务 (需要哪些精灵/动画)
- 场景任务 (需要哪些场景/节点)
- 脚本任务 (需要哪些逻辑)
- 测试任务 (需要验证什么)
```

### 2. 分层分发任务
```python
# 伪代码示例

# ============ 第一阶段: 设计层 (串行) ============
# 游戏设计师先出设计方案
if need_design:
    design_doc = await Task(agent="GameDesigner", prompt=design_task)

# 系统架构师根据设计出架构方案和核心代码
if need_architecture:
    arch_spec = await Task(agent="SystemArchitect", prompt=arch_task, context=design_doc)

# ============ 第二阶段: 实现层 (并行) ============
tasks = []

# 美术和脚本可以并行 (无依赖)
if need_art:
    tasks.append(Task(agent="Art", prompt=art_task, background=True))
if need_script:
    # Script Agent 需要遵循架构规范
    tasks.append(Task(agent="Script", prompt=script_task, context=arch_spec, background=True))

# 等待美术完成后启动场景
await art_task
if need_scene:
    tasks.append(Task(agent="Scene", prompt=scene_task))

# ============ 第三阶段: 集成测试 ============
await all_tasks
Task(agent="Integration", prompt="merge: arch -> art -> scene -> script")

# 最后测试
Task(agent="Test", prompt="run full test suite")
```

### 3. 任务分发决策树
```
用户需求
│
├─ 涉及新玩法/剧情/数值？
│  └─ YES → 启动 Game Designer
│
├─ 需要新系统/框架/重构？
│  └─ YES → 启动 System Architect
│
├─ 需要新美术资源？
│  └─ YES → 启动 Art Agent (可并行)
│
├─ 需要新场景？
│  └─ YES → 启动 Scene Agent (等美术)
│
├─ 需要新逻辑/功能？
│  └─ YES → 启动 Script Agent (遵循架构)
│
└─ 完成 → Integration → Test
```

### 4. 结果汇总
```
收集所有子代理的返回结果:
- 设计文档 (docs/design/)
- 架构规范 (docs/architecture/)
- 创建的文件列表
- 测试报告
- 截图验证
汇总后简洁回复用户
```

## 任务分发模板

### 示例1: 添加简单功能 - "添加一个敌人"

**主代理分析**:
```
需求: 添加敌人
├── 设计: 不需要 (简单功能)
├── 架构: 不需要 (使用现有框架)
├── 美术: 敌人精灵 (16x16, 4帧行走动画)
├── 场景: 敌人场景 (enemy.tscn)
├── 脚本: 敌人AI逻辑 (enemy.gd)
└── 测试: 验证敌人移动和碰撞
```

**并行任务分发**:
```
[并行启动 - 实现层]
├── Art Agent: 绘制 enemy.aseprite, 导出 enemy.png
└── Script Agent: 编写 enemy.gd (AI巡逻/追击逻辑)

[等待美术完成后]
└── Scene Agent: 创建 enemy.tscn, 引用 enemy.png

[集成]
└── Integration Agent: 合并所有分支到 main

[验证]
└── Test Agent: 运行游戏, 验证敌人行为, 返回截图
```

---

### 示例2: 添加复杂系统 - "添加背包系统"

**主代理分析**:
```
需求: 背包系统
├── 设计: 背包玩法设计、物品分类、交互方式
├── 架构: 背包数据结构、物品基类、存档集成
├── 美术: 背包UI、物品图标、拖拽效果
├── 场景: inventory_ui.tscn, item_slot.tscn
├── 脚本: 物品逻辑、背包操作
└── 测试: 物品增删改查、存档加载、UI交互
```

**分层任务分发**:
```
[设计层 - 串行]
├── Game Designer:
│   ├── 输出: docs/design/inventory.md
│   │   - 背包容量: 20格初始，可扩展
│   │   - 物品类型: 装备/消耗品/材料/任务
│   │   - 堆叠规则: 消耗品99上限
│   │   - 交互: 拖拽、右键菜单、双击使用
│   └── 提供数值和交互设计给架构师
│
└── System Architect:
    ├── 输出: docs/architecture/inventory_system.md
    ├── 创建: scripts/core/systems/inventory/
    │   ├── inventory_manager.gd (单例管理器)
    │   ├── item_data.gd (物品数据类)
    │   ├── item_slot.gd (格子逻辑基类)
    │   └── inventory_events.gd (背包事件)
    └── 更新: project.godot (注册Autoload)

[实现层 - 并行]
├── Art Agent:
│   ├── 背包面板 UI
│   ├── 物品格子 (普通/选中/禁用状态)
│   ├── 测试用物品图标 (药水、剑、金币)
│   └── 拖拽预览效果
│
└── Script Agent:
    ├── 继承架构师的 item_slot.gd 实现具体逻辑
    ├── 实现物品使用效果
    └── 在 auto_test.gd 添加背包测试用例

[等待美术完成后]
└── Scene Agent:
    ├── 创建 scenes/ui/inventory_panel.tscn
    ├── 创建 scenes/ui/item_slot.tscn
    └── 集成到主场景

[集成]
└── Integration Agent:
    合并顺序: arch -> art -> scene -> script

[验证]
└── Test Agent:
    ├── 测试: 添加物品、移除物品、堆叠、排序
    ├── 测试: 存档保存/读取背包
    └── 截图: 背包UI各状态
```

---

### 示例3: 添加核心系统 - "添加人才招募系统"

**主代理分析**:
```
需求: 人才招募系统
├── 设计: 招募机制、人才属性、成长系统
├── 架构: 人才数据结构、招募池、队伍管理
├── 美术: 招募UI、人才立绘、属性图标
├── 场景: recruitment.tscn, character_card.tscn
├── 脚本: 招募逻辑、随机算法、队伍管理
└── 测试: 招募概率、人才数据、UI流程
```

**分层任务分发**:
```
[设计层]
├── Game Designer:
│   ├── docs/design/recruitment.md
│   │   - 招募货币: 招募令 (免费/付费)
│   │   - 稀有度: 普通(60%)/稀有(30%)/传说(10%)
│   │   - 保底机制: 10次必出稀有，50次必出传说
│   │   - 人才属性: 攻击/防御/速度/技能
│   └── docs/design/characters.md
│       - 人才列表和属性设计
│
└── System Architect:
    ├── docs/architecture/recruitment_system.md
    ├── scripts/core/systems/recruitment/
    │   ├── recruitment_manager.gd (招募管理器)
    │   ├── character_data.gd (人才数据类)
    │   ├── gacha_pool.gd (抽卡池算法)
    │   └── team_manager.gd (队伍管理)
    └── scripts/core/base/character_base.gd (人才基类)

[实现层 - 并行]
├── Art Agent: 招募UI、人才卡片、动画效果
└── Script Agent: 具体人才实现、招募动画、队伍操作

[后续步骤省略...]
```

## 命令参考

### 启动子代理
```javascript
// ========== 设计层 (通常串行) ==========
// 游戏设计师
Task(subagent_type="general-purpose", prompt="[Game Designer Agent] 设计背包系统玩法...")

// 系统架构师 (等设计师完成后)
Task(subagent_type="general-purpose", prompt="[System Architect Agent] 根据设计文档实现背包系统框架...")

// ========== 实现层 (尽量并行) ==========
// 并行启动美术和脚本代理
Task(subagent_type="general-purpose", prompt="[Art Agent] ...", run_in_background=true)
Task(subagent_type="general-purpose", prompt="[Script Agent] ...", run_in_background=true)

// 顺序启动场景代理 (等美术)
Task(subagent_type="general-purpose", prompt="[Scene Agent] ...")

// 测试代理
Task(subagent_type="general-purpose", prompt="[Test Agent] ...")
```

### Git 操作
```bash
# 切换到 worktree
cd .worktrees/arch  # 或 art/scene/script

# 提交更改
git add -A && git commit -m "feat(arch): add inventory system framework"

# 合并到 main (按顺序)
git checkout main
git merge feature/arch-current --no-ff -m "Merge arch: inventory framework"
git merge feature/art-current --no-ff -m "Merge art: inventory UI"
git merge feature/scene-current --no-ff -m "Merge scene: inventory scenes"
git merge feature/script-current --no-ff -m "Merge script: inventory logic"
```

## 注意事项

1. **主代理保持干净**: 只做需求分析和任务分发，不直接操作文件
2. **设计先行**: 复杂功能必须先由 Game Designer 出设计方案
3. **架构规范**: Script Agent 必须遵循 System Architect 的架构规范
4. **子代理专注单一职责**: 每个代理只做自己领域的事
5. **并行优先**: 无依赖的任务尽量并行执行
6. **测试驱动**: 每次集成后必须运行测试验证
7. **截图验证**: 测试代理必须返回截图供主代理确认
8. **文档同步**: 设计和架构文档必须与代码同步更新

## 目录结构规范

```
Vessels/
├── project.godot
├── .mcp.json
├── CLAUDE.md
│
├── docs/                      # 文档目录
│   ├── design/               # 游戏设计文档 (Game Designer)
│   │   ├── story.md          # 剧情世界观
│   │   ├── mechanics.md      # 玩法机制
│   │   ├── inventory.md      # 背包系统设计
│   │   └── recruitment.md    # 招募系统设计
│   └── architecture/         # 架构文档 (System Architect)
│       ├── overview.md       # 架构总览
│       ├── systems.md        # 系统模块
│       └── patterns.md       # 设计模式
│
├── assets/
│   ├── scripts/              # Aseprite Lua 脚本
│   └── sprites/              # 精灵图片
│
├── scenes/
│   ├── main.tscn
│   ├── ui/                   # UI 场景
│   └── entities/             # 实体场景
│
├── scripts/
│   ├── core/                 # 核心框架 (System Architect)
│   │   ├── autoload/         # 全局单例
│   │   ├── base/             # 基类
│   │   └── systems/          # 游戏系统
│   ├── entities/             # 游戏实体 (Script Agent)
│   └── ui/                   # UI脚本
│
└── screenshots/              # 测试截图
```
