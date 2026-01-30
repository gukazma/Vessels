# Vessels - 系统架构文档

## 概述

本文档描述 Vessels 游戏的核心代码架构，包括模块划分、数据流和主要系统之间的关系。

## 架构图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            Godot 引擎层                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     全局单例 (Autoload)                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │   │
│  │  │  EventBus    │  │ GameManager  │  │ SaveManager  │          │   │
│  │  │  事件总线     │  │  游戏状态    │  │   存档系统   │          │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │   │
│  │  ┌──────────────┐                                               │   │
│  │  │ DataManager  │                                               │   │
│  │  │  数据管理    │                                               │   │
│  │  └──────────────┘                                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      游戏系统 (Systems)                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │   │
│  │  │ TimeSystem   │  │  Inventory   │  │  Character   │          │   │
│  │  │  时间系统    │  │   背包系统   │  │   角色管理   │          │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │   │
│  │  ┌──────────────┐  ┌──────────────┐                            │   │
│  │  │ BaseManager  │  │CombatSystem  │                            │   │
│  │  │  据点系统    │  │   战斗系统   │                            │   │
│  │  └──────────────┘  └──────────────┘                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                       基类 (Base Classes)                        │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │   │
│  │  │   Entity     │  │ StateMachine │  │ Interactable │          │   │
│  │  │   实体基类   │  │    状态机    │  │  可交互物    │          │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      游戏对象 (Game Objects)                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │   │
│  │  │   Player     │  │     NPC      │  │    Zombie    │          │   │
│  │  │    玩家      │  │    角色      │  │     僵尸     │          │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## 目录结构

```
scripts/
├── core/                      # 核心框架代码
│   ├── autoload/              # 全局单例 (Autoload)
│   │   ├── event_bus.gd       # 事件总线 - 解耦模块间通信
│   │   ├── game_manager.gd    # 游戏管理 - 状态控制、流程管理
│   │   ├── save_manager.gd    # 存档管理 - 数据持久化
│   │   └── data_manager.gd    # 数据管理 - 加载静态配置
│   │
│   ├── base/                  # 基类定义
│   │   ├── entity.gd          # 实体基类 - 生命值、移动、受伤
│   │   ├── state_machine.gd   # 状态机 - 通用状态管理
│   │   └── interactable.gd    # 可交互物基类
│   │
│   └── systems/               # 游戏系统
│       ├── time_system.gd     # 时间系统 - 日夜循环、事件触发
│       ├── inventory/         # 背包系统
│       │   ├── inventory_manager.gd
│       │   └── item_data.gd
│       ├── character/         # 角色系统
│       │   ├── character_manager.gd
│       │   └── character_data.gd
│       ├── base/              # 据点系统
│       │   └── base_manager.gd
│       └── combat/            # 战斗系统
│           └── combat_system.gd
│
├── entities/                  # 游戏实体 (继承自base)
│   ├── player/                # 玩家相关
│   ├── npc/                   # NPC相关
│   └── zombie/                # 僵尸相关
│
└── ui/                        # UI相关脚本
    ├── hud/                   # HUD界面
    ├── menus/                 # 菜单界面
    └── dialogs/               # 对话界面

data/                          # 静态数据文件
├── items.json                 # 物品数据
├── npcs.json                  # NPC数据
├── professions.json           # 职业数据
└── buildings.json             # 建筑数据
```

## 核心模块说明

### 1. EventBus (事件总线)

**职责**: 解耦模块间的通信，采用发布-订阅模式

**主要信号**:
- `time_tick(hour, minute)` - 游戏时间更新
- `day_changed(day)` - 天数变化
- `phase_changed(phase)` - 游戏阶段变化 (peace/apocalypse/survival)
- `player_stat_changed(stat, value)` - 玩家属性变化
- `item_added/removed(item_id, quantity)` - 物品增减
- `npc_relationship_changed(npc_id, value)` - NPC好感度变化
- `base_stat_changed(stat, value)` - 据点属性变化

**使用示例**:
```gdscript
# 发送事件
EventBus.player_stat_changed.emit("health", 80)

# 监听事件
EventBus.player_stat_changed.connect(_on_player_stat_changed)
```

### 2. GameManager (游戏管理器)

**职责**: 管理游戏整体状态和流程

**主要功能**:
- 游戏阶段管理 (和平期 → 末日爆发 → 生存期)
- 游戏暂停/继续
- 游戏胜利/失败检测
- 难度设置

**游戏阶段**:
```
PEACE      → 和平阶段 (Day 1-6)
APOCALYPSE → 末日爆发 (Day 7)
SURVIVAL   → 生存阶段 (Day 8+)
```

### 3. SaveManager (存档管理器)

**职责**: 处理游戏数据的保存和加载

**主要功能**:
- 保存游戏状态到 JSON 文件
- 加载存档数据
- 自动存档 (每天结束时)
- 存档槽位管理

**存档数据结构**:
```json
{
  "version": "1.0",
  "timestamp": "2026-01-31T12:00:00",
  "game_state": {
    "day": 5,
    "phase": "peace",
    "time": {"hour": 14, "minute": 30}
  },
  "player": {
    "position": {"x": 100, "y": 200},
    "stats": {"hp": 85, "hunger": 70, "stamina": 60},
    "profession": "office_worker",
    "money": 350
  },
  "inventory": [...],
  "npcs": {...},
  "base": {...}
}
```

### 4. DataManager (数据管理器)

**职责**: 加载和管理静态游戏数据

**主要功能**:
- 加载物品数据 (items.json)
- 加载NPC数据 (npcs.json)
- 加载职业数据 (professions.json)
- 加载建筑数据 (buildings.json)
- 提供数据查询接口

### 5. TimeSystem (时间系统)

**职责**: 管理游戏内时间流逝

**时间参数**:
- 1 游戏小时 = 25 秒现实时间
- 1 游戏天 = 10 分钟现实时间
- 支持时间加速 (睡眠、工作时)

**主要功能**:
- 时间流逝计算
- 日夜循环
- 时间事件触发
- 暂停/恢复时间

### 6. InventoryManager (背包系统)

**职责**: 管理玩家和据点的物品

**主要功能**:
- 物品添加/移除
- 堆叠逻辑处理
- 容量限制检查
- 物品使用效果

### 7. CharacterManager (角色管理)

**职责**: 管理NPC数据和交互

**主要功能**:
- NPC状态追踪
- 好感度系统
- 招募逻辑
- 任务队员分配

### 8. BaseManager (据点系统)

**职责**: 管理据点建设和资源

**主要功能**:
- 据点属性管理 (防御、舒适度等)
- 建筑建造/升级
- 每日消耗计算
- 夜间防御结算

### 9. CombatSystem (战斗系统)

**职责**: 处理战斗相关逻辑

**主要功能**:
- 伤害计算
- 武器系统
- 僵尸AI接口
- 战斗效果处理

## 数据流

### 游戏初始化流程

```
1. Godot启动
   ↓
2. Autoload单例初始化
   - EventBus
   - DataManager (加载JSON数据)
   - GameManager
   - SaveManager
   ↓
3. 主场景加载
   ↓
4. 检查存档
   ├─ 有存档 → 加载存档数据
   └─ 无存档 → 显示新游戏界面 (选择职业)
   ↓
5. 初始化游戏系统
   - TimeSystem
   - InventoryManager
   - CharacterManager
   - BaseManager
   ↓
6. 游戏开始
```

### 典型事件流: 玩家拾取物品

```
1. 玩家与物品碰撞
   ↓
2. Interactable.interact() 被调用
   ↓
3. InventoryManager.add_item(item_id, quantity)
   ├─ 检查容量
   ├─ 处理堆叠
   └─ 更新背包数据
   ↓
4. EventBus.item_added.emit(item_id, quantity)
   ↓
5. 监听者响应
   ├─ UI更新背包显示
   ├─ 任务系统检查进度
   └─ 音效系统播放拾取音效
```

### 典型事件流: 日夜循环

```
1. TimeSystem._process(delta)
   ↓
2. 累计时间，计算游戏时间
   ↓
3. 每分钟: EventBus.time_tick.emit(hour, minute)
   ↓
4. 跨天检测
   ├─ EventBus.day_changed.emit(new_day)
   ├─ GameManager检查阶段转换
   └─ BaseManager结算每日消耗
   ↓
5. 阶段转换检测 (Day 7)
   ├─ EventBus.phase_changed.emit("apocalypse")
   ├─ GameManager触发末日事件
   └─ 各系统响应状态变化
```

## 设计原则

### 1. 单一职责
每个类/模块只负责一个明确的功能领域。

### 2. 事件驱动
使用 EventBus 解耦模块间通信，避免直接依赖。

### 3. 数据驱动
游戏配置存储在 JSON 文件中，便于调整和扩展。

### 4. 组合优于继承
使用组件化设计，通过组合实现功能扩展。

### 5. 类型安全
充分利用 GDScript 的类型标注，提高代码可读性和安全性。

## 扩展指南

### 添加新物品
1. 在 `data/items.json` 中添加物品数据
2. 如有特殊效果，在 `InventoryManager` 中添加处理逻辑

### 添加新NPC
1. 在 `data/npcs.json` 中添加NPC数据
2. 创建NPC精灵资源
3. 如有特殊技能，在 `CharacterManager` 中添加逻辑

### 添加新建筑
1. 在 `data/buildings.json` 中添加建筑数据
2. 创建建筑精灵资源
3. 如有特殊功能，在 `BaseManager` 中添加逻辑

### 添加新游戏事件
1. 在 `EventBus` 中定义新信号
2. 在相关系统中发送信号
3. 在需要响应的模块中连接信号

---

*文档版本: 1.0*
*最后更新: 2026-01-31*
