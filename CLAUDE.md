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
    ┌───────────────────────────────────────────────────────┐
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
git worktree add .worktrees/art -b feature/art-current
git worktree add .worktrees/scene -b feature/scene-current
git worktree add .worktrees/script -b feature/script-current
```

### Worktree 目录结构
```
Vessels/                    # 主工作目录 (main 分支)
├── .worktrees/
│   ├── art/               # 美术代理工作目录
│   ├── scene/             # 场景代理工作目录
│   └── script/            # 脚本代理工作目录
```

## 主代理工作流程

当用户提出需求时，主代理按以下步骤执行:

### 1. 需求分析
```
解析用户需求，拆分为:
- 美术任务 (需要哪些精灵/动画)
- 场景任务 (需要哪些场景/节点)
- 脚本任务 (需要哪些逻辑)
- 测试任务 (需要验证什么)
```

### 2. 并行分发任务
```python
# 伪代码示例
tasks = []

# 美术和脚本可以并行 (无依赖)
if need_art:
    tasks.append(Task(agent="Art", prompt=art_task, background=True))
if need_script:
    tasks.append(Task(agent="Script", prompt=script_task, background=True))

# 等待美术完成后启动场景
await art_task
if need_scene:
    tasks.append(Task(agent="Scene", prompt=scene_task))

# 全部完成后集成
await all_tasks
Task(agent="Integration", prompt="merge all feature branches")

# 最后测试
Task(agent="Test", prompt="run full test suite")
```

### 3. 结果汇总
```
收集所有子代理的返回结果:
- 创建的文件列表
- 测试报告
- 截图验证
汇总后简洁回复用户
```

## 任务分发模板

### 添加新功能示例: "添加一个敌人"

**主代理分析**:
```
需求: 添加敌人
├── 美术: 敌人精灵 (16x16, 4帧行走动画)
├── 场景: 敌人场景 (enemy.tscn)
├── 脚本: 敌人AI逻辑 (enemy.gd)
└── 测试: 验证敌人移动和碰撞
```

**并行任务分发**:
```
[并行启动]
├── Art Agent: 绘制 enemy.aseprite, 导出 enemy.png
└── Script Agent: 编写 enemy.gd (AI巡逻/追击逻辑)

[等待美术完成后]
└── Scene Agent: 创建 enemy.tscn, 引用 enemy.png

[集成]
└── Integration Agent: 合并所有分支到 main

[验证]
└── Test Agent: 运行游戏, 验证敌人行为, 返回截图
```

## 命令参考

### 启动子代理
```javascript
// 并行启动美术和脚本代理
Task(subagent_type="general-purpose", prompt="[Art Agent] ...", run_in_background=true)
Task(subagent_type="general-purpose", prompt="[Script Agent] ...", run_in_background=true)

// 顺序启动场景代理
Task(subagent_type="general-purpose", prompt="[Scene Agent] ...")

// 测试代理
Task(subagent_type="general-purpose", prompt="[Test Agent] ...")
```

### Git 操作
```bash
# 切换到 worktree
cd .worktrees/art

# 提交更改
git add -A && git commit -m "feat(art): add enemy sprite"

# 合并到 main
git checkout main
git merge feature/art-current --no-ff -m "Merge art: enemy sprite"
```

## 注意事项

1. **主代理保持干净**: 只做需求分析和任务分发，不直接操作文件
2. **子代理专注单一职责**: 每个代理只做自己领域的事
3. **并行优先**: 无依赖的任务尽量并行执行
4. **测试驱动**: 每次集成后必须运行测试验证
5. **截图验证**: 测试代理必须返回截图供主代理确认
