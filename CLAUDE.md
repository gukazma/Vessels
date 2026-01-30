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
