# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述
俯视角策略救援游戏。玩家操控角色投掷光锚，引导难民回到安全屋。
- **引擎**: Godot 4.7
- **语言**: GDScript
- **分辨率**: 1920×1080
- **主分支**: `feature/core-gameplay`

## 代码规范
- **所有 .gd 文件使用 Tab 缩进**，Edit 工具匹配字符串时需注意
- GDScript 静态类型：动态调用（如 `cart.get_caught_anchor()`）返回值需显式标注类型 `var a: Anchor = ...`
- 物理回调中禁止修改场景树，用 `call_deferred()` 延迟
- 提交：用户说"提交"/"推送到github"时才 commit+push，否则只改不提交

## 核心架构

### 碰撞层
| 位值 | 层 | 用途 |
|------|------|------|
| 1 | refugees | 难民碰撞 |
| 2 | attraction | 吸引检测 |
| 4 | rescue | 安全屋救援 |
| 8 | player | 玩家 |
| 16 | danger | 危险区 |
| 32 | lava | 岩浆阻挡/锚点检测 |

### 难民 AI (`refugee.gd`)
```
WANDERING → 无吸引源时随机徘徊
SEEKING → 被吸引，沿锚点链走向安全屋（BFS）
RESCUED → 到达安全屋
```
- `_physics_process` 顺序：`_apply_anchor_effects()` → `_update_state()` → `_process_movement()` → `_update_animation()`
- 驱赶锚点最高优先级：`_repel_linger > 0` 时跳过所有寻路，直接速度背向圆心移动
- 矿车锚点：弹簧追踪 + 个人偏移（`_minecart_follow_offset`），不用 NavigationAgent
- 安全屋永远第一优先

### 锚点系统
- `world.gd:get_attraction_sources()` — 返回 SafeHouse + anchors_container 子节点 + 矿车上的锚点
- `world.gd:find_next_anchor_to_safehouse()` — BFS 图算法，锚点间距 ≤ r1+r2 即连通
- 危险区（`danger_zone.gd`）：圆形 Area2D，`zone_radius`，NPC进入死亡，锚点可投入
- 岩浆区（`lava_zone.gd`）：StaticBody2D 阻挡，AnchorDetector 碰撞层 32，锚点丢入重生

### 矿车系统 (`minecart.gd`)
- extends PathFollow2D，放在 Path2D（Rail）下自动沿路径移动
- `CatchZone` Area2D 接住锚点 → reparent 到矿车下
- `get_caught_anchor()` / `release_anchor()` 供 player 和 world 查询
- 加入 `"minecarts"` 组

### 移动安全屋 (`moving_safe_house.gd`)
- extends PathFollow2D，跟矿车一样放在 Rail 下
- 超出地图边界（x<-50, x>1970, y<-50, y>1130）触发 `GameManager.level_failed`
- 子节点在 `SafeHouseBody` 下（RangeSprite、RescueArea）

### UI 流程
标题 → 直接第一关 → 胜利下一关 → 通关界面
（已取消选关，`main.gd:on_start_game()` 直接 `_start_current_level()`）

### 关卡配置
- `resources/levels/level_*.tres` — LevelData 资源
- `player_spawn_position` — 玩家出生点，留 (0,0) 自动放安全屋右边
- `is_moving_safe_house` + `safe_house_speed` + `safe_house_path_path` — 移动安全屋

## 关键依赖关系
- `World` 是中介者：难民/玩家/锚点通过 `get_tree().get_first_node_in_group("world")` 找到它
- `GameManager` 是 autoload 单例：管理救援计数、关卡状态、胜负信号
- Player 拾取锚点：遍历 `world/Anchors` 子节点 + `"minecarts"` 组矿车，纯距离判断
- 锚点 `picked_up` 信号 → `queue_free()`，Player 存储 `_held_anchor: PackedScene`
