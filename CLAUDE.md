# Safe Anchor — 项目文档

## 项目概述
俯视角策略救援游戏。玩家操控角色在战场上拾取和投掷光锚，引导迷途难民回到安全屋。

- **引擎**: Godot 4.7
- **语言**: GDScript
- **分辨率**: 1920×1080
- **分支**: `feature/core-gameplay`
- **GitHub**: `https://github.com/kunk70352-png/Safe-Anchor.git`

## 目录结构
```
src/
├── autoload/game_manager.gd    # 全局状态管理（救援计数、关卡切换）
├── main/main.gd                # 入口，管理UI切换流程
├── world/world.gd              # 世界管理（导航、关卡初始化、BFS寻路）
├── player/player.gd            # 玩家（WASD移动、鼠标左键蓄力投掷）
├── refugee/refugee.gd          # 难民AI（状态机、BFS锚点链寻路、冰面逻辑）
├── anchor/
│   ├── anchor.gd               # 锚点基类（缩小、速度影响、驱赶、危险区重生）
│   ├── anchor_type1.tscn       # 初始锚点（蓝，r=180，shrink=2/s）
│   ├── anchor_type2.tscn       # 大范围锚点（绿，r=250，shrink=6/s）
│   ├── anchor_type3.tscn       # 驱赶锚点（红，r=200，repel=true）
│   ├── danger_zone.gd/tscn     # 危险区（NPC进入死亡，zone_size可调）
│   └── lava_zone.gd/tscn       # 岩浆区（阻挡移动，锚点重生，zone_size可调）
├── safe_house/safe_house.gd    # 安全屋（吸引+救援检测）
├── objects/
│   ├── minecart.gd/tscn        # 矿车（沿Path2D循环，接住锚点）
│   └── rail.tscn               # 铁轨（Path2D定义路线）
└── ui/
    ├── title_screen.gd/tscn    # 标题界面
    ├── level_select.gd/tscn    # 关卡选择
    ├── hud.gd/tscn             # HUD（关卡名、救援进度、锚点状态）
    ├── victory_screen.gd/tscn  # 胜利界面
    ├── defeat_screen.gd/tscn   # 失败界面
    └── completion_screen.gd/tscn # 通关界面

resources/
├── levels/level_data.gd        # LevelData Resource（关卡参数）
├── levels/level_1~3.tres       # 关卡数据
├── levels/maps/level_1~3_map.tscn  # 每关独立TileMap
├── anchor_data.gd              # AnchorData Resource（锚点类型数据）
└── default_anchor.tres
```

## 核心架构

### 碰撞层
| 层 | 名称 | 用途 |
|----|------|------|
| 1 | refugees | 难民碰撞 |
| 2 | attraction | 吸引检测 |
| 3 | rescue | 安全屋救援检测 |
| 4 | player | 玩家 |
| 5 | danger | 危险区(16)、岩浆区(32) |
| 6 | lava | 岩浆阻挡 |

### 难民 AI 状态机
```
WANDERING → 无吸引源时随机徘徊（wander_range限制）
SEEKING → 被吸引，按BSF图算法沿锚点链走向安全屋
RESCUED → 到达安全屋，缩小消失
```

### 锚点寻路（BFS图算法）
World.find_next_anchor_to_safehouse() 构建锚点重叠图，BFS找最短路径到安全屋。锚点间 dist ≤ r1+r2 即连通。

### UI 流程
标题→选关→游戏→胜利/失败→选关（或通关界面）

## 输入映射
- WASD: 移动玩家
- 鼠标左键: 蓄力投掷（按住蓄力，松手投掷）
- K键: 调试跳过当前关卡

## 关卡配置
编辑 `resources/levels/level_*.tres`：
- `wander_range`: NPC徘徊范围
- `refugee_spawn_positions`: NPC出生点
- `type1/2/3_positions`: 预置三种锚点位置
- `is_ice_level`: 冰面关卡（NPC不主动徘徊）
- `tile_map_path`: 关卡地图场景路径

每关独立TileMap在 `resources/levels/maps/` 编辑。

## 区域系统
- **危险区** (`danger_zone.tscn`): 拖入场景，设 `zone_size`。NPC进入→死亡→失败。
- **岩浆区** (`lava_zone.tscn`): 拖入场景，设 `zone_size`。阻挡移动，锚点丢入→重生。

## 已实现功能
- 三种锚点类型（普通/大范围/驱赶），随时间缩小
- BFS图算法锚点链寻路
- 玩家无初始锚点，鼠标瞄准投掷
- NPC徘徊范围限制
- 无时间限制，任一NPC死亡即失败（via danger_zone）
- 矿车+铁轨系统
- 冰面关卡逻辑
- 每关独立TileMap地图
- 标题/选关/通关界面
- K键调试跳过

## 待处理
- 移动安全屋（已创建脚本，未集成到关卡系统）
- 危险区和岩浆区需添加@tool可视化
- 关卡数据文件可能被Godot编辑器/linter修改导致字段丢失
