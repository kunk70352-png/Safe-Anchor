# Safe Anchor — AGENTS.md

> Godot 4.7 | 2D 俯视角 | 1920×1080 | GDScript | 中文注释

---

## 核心规则（必须遵守）

1. **改动前先出方案+风险，确认后执行**
2. **提交前展示 commit message，确认后再 commit**
3. 写入 .gd/.tscn/.tres 必须用无 BOM UTF-8：
   `[System.IO.File]::WriteAllText("路径", $内容, (New-Object System.Text.UTF8Encoding $false))`
4. 不要改 load_steps，不要直接编辑 .godot/
5. 不要硬编码锚点类型，用 AnchorData Resource

---

## 目录结构

```
src/
├── main/        # 主入口
├── autoload/    # GameManager 单例
├── player/      # CharacterBody2D, WASD移动, 鼠标蓄力投掷
├── refugee/     # NPC AI, NavigationAgent2D, 三状态机
├── anchor/      # 锚点 + 岩浆区 + 危险区
├── safe_house/  # 安全屋
├── objects/     # 矿车、铁轨
├── world/       # World 容器 + 关卡编辑器
└── ui/          # 标题/选关/HUD/胜利/失败/通关
resources/levels/  # LevelData .tres + 地图 .tscn
assets/sprites/    # 素材
```

---

## 编码规范

```gdscript
## 类文档注释
class_name MyClass
extends Node2D

# ---- 信号 ----
signal xxx

# ---- @export ----
@export var speed: float = 100.0

# ---- 内部状态 ----
var _private_var: int = 0

# ---- @onready ----
@onready var sprite: Sprite2D = $"Sprite2D"

# ---- 生命周期 ----
func _ready() -> void: ...

# ---- 功能块 ----
```

- ## 双井号 = 文档注释，# ---- xxx ---- = 分隔线
- _ 前缀 = 私有，文件末尾留一个空行

---

## 架构要点

- GameManager autoload 信号总线（观察者模式），模块间不直接调用
- AnchorData / LevelData Resource 驱动，编辑器检查器调参
- 难民 BFS：world.find_next_anchor_to_safehouse() 沿锚链寻路
- 难民 3 状态：WANDERING → SEEKING → RESCUED，优先选最新放置的锚点
- 边界岩浆：world.gd _setup_border_lava() 动态创建，上/左/右 75px，下 95px
- 关卡编辑：LevelPlacer + PlacerMarker，拖拽后 Ctrl+S 自动同步 .tres

---

## 六个关卡

| # | 名称 | 锚点限制 |
|---|------|----------|
| 1 | 新手关 | 无 |
| 2 | 过桥 | 3 |
| 3 | 矿车 | 3 |
| 4 | 飞屋 | 2 |
| 5 | 反向锚1 | 3 |
| 6 | 反向锚2 | 2 |
