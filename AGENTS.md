# Safe Anchor — 项目 AGENTS.md

> Godot 4.7 | Forward Plus | 1920×1080 | GDScript

---

## 项目概览

Safe Anchor 是一款 2D 俯视角空间规划解谜游戏。玩家投掷锚点铺设安全路径，引导难民沿锚链走向安全屋。

- **引擎**: Godot 4.7，Forward Plus 渲染器，D3D12 驱动
- **分辨率**: 原生 1920×1080，stretch_mode=canvas_items，stretch_aspect=expand
- **语言**: GDScript，中文注释，中文 commit message
- **分支**: eature/core-gameplay

---

## 代码组织规范

所有 GDScript 文件遵循统一的区块布局：

`gdscript
## 类文档注释（双井号 ##）
class_name MyClass
extends Node2D

# ---- 信号 ----
signal something_happened

# ---- 常量 ----
const SCENE := preload("res://...")

# ---- @export 可调参数 ----
@export var speed: float = 100.0

# ---- 内部状态 ----
var _state: int = 0

# ---- @onready 节点引用 ----
@onready var sprite: AnimatedSprite2D = $"AnimatedSprite2D"

# ---- 生命周期 ----
func _ready() -> void:
	...

func _physics_process(delta: float) -> void:
	...

# ---- 功能函数（按职责分块） ----
# 用 # ---- xxx ---- 做分隔线
`

**要点**:
- ## 双井号用于类/函数文档注释
- # ---- xxx ---- 用于功能块分隔
- _ 前缀表示私有变量/函数
- 文件末尾留一个空行
- **写入 .gd/.tscn/.tres 文件必须用无 BOM 的 UTF-8**，否则 Godot 报 Parse Error

---

## 目录结构

`
Safe Anchor/
├── project.godot
├── resources/
│   ├── levels/             # LevelData 资源 + 关卡地图场景
│   ├── anchor_data.gd      # AnchorData Resource 类定义
│   └── default_anchor.tres # 默认锚点数据
├── src/
│   ├── main/               # 主场景入口
│   ├── autoload/           # GameManager 全局单例
│   ├── player/             # 玩家（CharacterBody2D）
│   ├── refugee/            # 难民 AI（CharacterBody2D）
│   ├── anchor/             # 锚点 + 危险区 + 岩浆区
│   ├── safe_house/         # 安全屋（含移动安全屋）
│   ├── objects/            # 矿车、铁轨等物件
│   ├── world/              # World 场景（地图容器）
│   └── ui/                 # 标题/选关/HUD/胜利/失败/通关界面
└── assets/sprites/         # 精灵图素材
`

---

## 核心架构

### 信号通信（GameManager 观察者模式）

项目使用 GameManager autoload 单例作为全局事件总线，模块间通过信号通信，不直接互相调用方法：

| 信号 | 发送者 | 用途 |
|------|--------|------|
| efugee_rescued(total, target) | GameManager | 难民被救出时更新 HUD |
| level_completed(stats) | GameManager | 关卡完成 |
| level_failed(stats) | GameManager | 关卡失败 |
| nchor_placed(used, max) | GameManager | 锚点被放置时更新计数 |

### Resource 数据驱动

游戏数据抽成 .tres 资源文件，在编辑器检查器中直接调整：

- **AnchorData** (esources/anchor_data.gd): 锚点名称、吸引半径、缩小速度、速度加成、驱赶模式、贴图
- **LevelData** (esources/levels/level_data.gd): 关卡编号、名称、难民数量/速度/生成位置、锚点限制、安全屋参数、冰面标记、预置锚点位置

新建锚点类型：文件系统右键 → 新建 Resource → AnchorData → 填入参数，拖入场景即可。

---

## 核心系统

### 玩家 (Player)
- WASD 移动，鼠标左键按住蓄力→松开投掷
- 投掷方向由鼠标位置决定，抛物线预览
- 拾取锚点：走到锚点旁自动拾取（距离检测 pickup_dist）
- _held_anchor: 当前持有的锚点场景引用（PackedScene）

### 锚点 (Anchor)
- Node2D，通过 ttraction_radius 吸引/驱赶难民
- 关键属性：epel（驱赶模式）、shrink_speed（半径缩小速度）、speed_modifier（难民速度加成）、nchor_color（显示颜色）
- 碰到 DangerDetector → 回到出生位置并重置半径
- 拾取：玩家走近 → pick_up() → queue_free()

### 难民 (Refugee)
- CharacterBody2D，NavigationAgent2D 寻路
- 三种状态：WANDERING（漫游）→ SEEKING（被锚点吸引）→ RESCUED（到达安全屋）
- 在锚点范围内会减速（nchor_slow_mult）
- 驱赶模式：被 repel=true 的锚点推开
- 冰面关：不主动漫游，依赖惯性

### 安全屋 (SafeHouse)
- 有吸引半径，难民到达后触发救援计数
- 移动安全屋 (moving_safe_house.gd): 沿路径移动

---

## 关卡系统

当前有 3 个关卡 (esources/levels/level_1~3.tres)：

| 关卡 | 名称 | 目标 |
|:--:|------|:--:|
| 1 | 初次救援 | 3人 |
| 2 | — | — |
| 3 | — | — |

关卡地图场景位于 esources/levels/maps/level_N_map.tscn，包含 TileMapLayer、岩浆/危险区、铁轨等。

---

## UI 流程

`
TitleScreen → LevelSelect → Main (World + HUD) → Victory/Defeat
										 ↓ (全部关卡完成)
									CompletionScreen
`

- **TitleScreen**: 标题 + 背景故事文字 + 开始/退出按钮
- **LevelSelect**: 列出所有关卡，显示编号+名称+目标人数
- **HUD**: 游戏中显示难民计数、锚点计数等
- **VictoryScreen**: 单关完成
- **DefeatScreen**: 关卡失败
- **CompletionScreen**: 全部关卡通过

---

## 物件系统

- **Rail** (Path2D): 铁轨路径，Curve2D 定义
- **Minecart** (PathFollow2D): 沿铁轨循环移动，可接住投掷的锚点
- **DangerZone**: 危险区，NPC 踩到即死
- **LavaZone**: 岩浆区，阻挡锚点投掷

---

## 编码注意事项

### 写入 GDScript 文件（PowerShell）
`
[System.IO.File]::WriteAllText("路径.gd", , (New-Object System.Text.UTF8Encoding $false))
`
不要用 Set-Content -Encoding UTF8（会加 BOM 导致 Godot 报错）。

### Git 规范
- Commit message: 中文，"动词+内容"（如"修复矿车碰撞检测"）
- 提交前 git status + git diff
- 不执行 git reset --hard、git push --force 等高风险命令

### 不要做的事
- 不要硬编码锚点类型，用 AnchorData Resource
- 不要改 load_steps 数字，Godot 编辑器会自动维护
- 不要直接编辑 .godot/ 目录下的文件
