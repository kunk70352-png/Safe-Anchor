# 从 godot_demo 到 Safe Anchor —— 项目交接手册

> 本文档供新加入的队友快速了解过往经验、技术规范和 Safe Anchor 项目全貌。
> 阅读时间：约 15 分钟。

---

## 一、我们做过什么

### 1.1 godot_demo（单房间战斗 Demo）

- **规模**：4 个脚本 + 4 个场景，约 150 行代码
- **功能**：玩家八方向移动 + 鼠标攻击、敌人追踪 + 掉落金币、房间清空 → 选择奖励 → 进入下一房间
- **后续**：演变成了 mini-survivor

### 1.2 mini-survivor（类幸存者 Demo）

- **规模**：10 个脚本 + 7 个场景 + 6 个 Resource，约 800 行代码
- **功能**：自动攻击（三种武器：狙击枪/机关枪/霰弹枪）、敌人生成（两种普通敌人 + Boss）、经验球 + 升级三选一、难度递增、Boss 倒计时
- **架构亮点**：Resource 数据驱动、信号通信、GameBalance 集中管理数值
- **运行**：Godot 4.7，Forward Plus (D3D12) 渲染器

---

## 二、技术经验教训

### 2.1 BOM 编码 —— 最大的坑（踩过两次）

在 Windows 上用 PowerShell 写 `.gd` / `.tscn` / `.tres` 文件时：

| 写法 | 结果 |
|------|------|
| `Set-Content -Encoding UTF8` | ❌ 写入 BOM 头（EF BB BF），Godot 报 Parse Error |
| `Out-File -Encoding UTF8` | ❌ 同上 |
| `.NET WriteAllText` + `UTF8Encoding($false)` | ✅ 无 BOM，Godot 正常加载 |

**正确写法：**

```powershell
[System.IO.File]::WriteAllText(
	"文件路径.gd",
	$代码内容,
	(New-Object System.Text.UTF8Encoding $false)
)
```

**教训**：任何由脚本生成的 Godot 文本文件，永远用无 BOM 的方式写入。如果 Godot 报莫名其妙的 Parse Error（尤其是文件第一行），先检查有没有 BOM。

---

### 2.2 代码组织规范（四段式）

mini-survivor 的所有脚本遵循统一的四段式布局，读起来非常清晰：

```gdscript
extends Node2D
## 类文档注释：用两个 #，说明这个脚本的职责

# ==== 信号 ====
signal xxx

# ==== 常量 ====
const SCENE := preload("res://...")

# ==== @export 可调参数 ====
@export var speed: float = 300.0

# ==== 内部状态 ====
var hp: int
var alive: bool = true

# ==== @onready 节点引用 ====
@onready var sprite: Sprite2D = $"Sprite2D"
@onready var label: Label = $"UI/Label"

# ==== 生命周期 ====
func _ready() -> void:
	...

func _physics_process(delta: float) -> void:
	...

# ==== 功能函数（按职责分块） ====
# 用 # ==== xxx ==== 做分隔线

# ==== 伤害 ====
func take_damage(amount: int) -> void:
	...

# ==== 攻击 ====
func attack() -> void:
	...
```

**规范要点：**
- `##` 双井号用于类/函数文档注释
- `#` 单井号用于行内注释
- `# ==== xxx ====` 用于功能块分隔
- 文件末尾必须有一个空行

---

### 2.3 信号通信 —— 核心架构

两个项目都用信号（signal）做节点间通信，**不直接互相调用方法**：

```
玩法逻辑（Main.gd）
	↑↓ 信号
玩家（Player.gd）    敌人（Enemy.gd）    金币（Coin.gd）
```

**常用模式：**

```gdscript
# 1. 在子节点定义信号
signal died(position: Vector2, exp_drop: int)

# 2. 触发
func die() -> void:
	died.emit(global_position, 5)

# 3. 在 Main 中用代码连接（不在编辑器里连）
func _spawn_enemy() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	enemies.add_child(enemy)
	enemy.died.connect(_on_enemy_died)

func _on_enemy_died(pos: Vector2, exp: int) -> void:
	_spawn_exp_orb(pos)
```

**要点：**
- 项目使用 GameManager autoload 单例作为全局事件总线
- 信号连接写在生成节点的函数里（代码连接），不在编辑器界面拖线
- 跨场景通信统一走 GameManager 单例信号

---

### 2.4 Resource 数据驱动

mini-survivor 把游戏数据抽成 `.tres` 资源文件，而非硬编码在脚本里：

| Resource 类 | 存储内容 | 修改方式 |
|------------|---------|---------|
| `WeaponData` | 武器名、伤害、攻速、行为类型 | 编缉器里直接改 `.tres` |
| `EnemyArchetype` | 敌人名、血量、速度、颜色、贴图 | 同上 |
| `GameBalance` | 全部数值（生成间隔、成长曲线、Boss 时间） | 同上 |

**好处**：数值调优不需要改代码，在编辑器面板拖滑块就行。

**定义方式**：

```gdscript
class_name WeaponData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var attack_damage: int = 1
@export var attack_interval: float = 0.5
```

然后在文件系统中右键 → 新建 Resource → 选中 WeaponData → 填入数值，拖入脚本的 `@export var weapon: WeaponData` 即可。

---

### 2.5 其他经验

| 经验 | 说明 |
|------|------|
| **分组查节点** | 用 `add_to_group("enemy")` 和 `get_tree().get_nodes_in_group("enemy")` 替代遍历子节点 |
| **延迟调用** | 在可能已释放的节点上调用方法时用 `call_deferred("method")`，防止时序问题 |
| **碰撞检测** | 接触伤害走 `move_and_slide` 的 `get_slide_collision_count()`；范围检测走 `Area2D` |
| **暂停游戏** | 升级选奖励时用 `get_tree().paused = true`，UI 层设 `PROCESS_MODE_ALWAYS` |
| **重开游戏** | 用 `get_tree().reload_current_scene()` 一键重置 |
| **Forward Plus (D3D12)** | mini-survivor 用了兼容渲染器（性能好、低端机也能跑），Safe Anchor 建议沿用 |
| **分辨率** | 参照土豆兄弟用 原生 1920×1080（实际项目采用） |

---

## 三、Safe Anchor 项目介绍

### 3.1 游戏概念

> 末日降临后，世界只剩碎片与迷途者。你是最后的锚。—— 带他们回家。

**类型**：2D 俯视角 · 空间规划 puzzle

**核心循环**：观察关卡 → 选择锚类型 → 投掷锚点铺设安全路径 → 幸存者沿锚链走向安全屋

---

### 3.2 锚点系统（⚠️ 实际项目已改为 Resource 驱动）

| 锚类型 | 范围 | 特性 |
|-------|:--:|------|
| 🔵 正常锚 | 中 | 吸引幸存者走向它 |
| 🔴 反向锚 | 中 | 推开幸存者，用于躲避陷阱、驱赶、接力 |
| 🟡 缩小锚 | 大→小 | 初始范围大但持续缩小，用于抢时间窗口 |

**关键规则**：幸存者只在锚范围重叠时才能从一个锚走到下一个锚（锚链必须连续）。

---

### 3.3 已设计的关卡（⚠️ 实际项目仅 3 关）

| 关卡 | 名称 | 核心机制 |
|:--:|------|------|
| 1 | 初次引导 | 教学：基础投锚 + 铺路 |
| 2 | 推拉之间 | 正常锚 + 反向锚夹出一个斜向安全通道 |
| 3 | 窗口期 | 间歇火焰 + 缩小锚抢时间 |
| 4 | 弹球 | 纯反向锚接力推人，无正常锚 |
| 5 | 锚链接力 | 每种锚只有1个，需回收-重投 |
| 6 | 天平 | 幸存者踩平台 → 巨石抬起 → 抢时间铺路 |
| 7 | 涨潮 | 周期性涨水，三种锚配合避水 |
| 8 | 传送带 | 横向传送带偏移幸存者，锚修正方向 |
| 9 | 冰面 | 幸存者惯性滑行，锚做刹车和转向 |
| 10 | 开门接力 | 幸存者分流踩踏板开门 |
| 11 | 镜面世界 | 上下半区锚镜像对称 |
| 12 | 破裂地板 | 地板踩过就碎，不能回头 |
| 13 | 共振通道 | 同类锚之间生成瞬移通道 |
| 14 | 最后一人 | 幸存者只跟玩家走，锚间接辅助 |
| 15 | 断桥 | 综合融合关 |

> 完整关卡列表见飞书文档：[Anchor · Game Jam 创意脑暴](https://fwc1lwm6891.feishu.cn/wiki/Ounow1nDiiBwk7kbsw5cb20DnYe)

---

### 3.4 MVP 范围

| 模块 | 内容 |
|------|------|
| 玩家 | WASD 移动，鼠标左键蓄力投掷（方向指向鼠标），走到锚点旁拾取 |
| 锚点 | 正常锚 + 缩小锚（反向锚 Version 2） |
| 锚链 | 范围重叠即连通，可视化连线 |
| 幸存者 | 沿锚链走向安全屋，暂不区分类型 |
| 安全屋 | 到达后计数 |
| 障碍物 | 墙壁阻挡放置和移动 |
| 流程 | 实时操作，无阶段切换（⚠️ 文档原计划已变更） |
| 关卡 | 1 个测试关 |
| UI | 锚切换指示 + 幸存者计数 + 状态文字 |

**不做**：美术素材（纯色方块代替）、音效、多幸存者类型、角色升级、多关卡。

---

### 3.5 文案素材（已确定）

#### 标题界面（⚠️ 实际文案已变更，见 title_screen.tscn）

| 英文 | 中文 |
|------|------|
| The world broke. | 世界崩塌了。 |
| They got lost. | 他们迷失了。 |
| You are the last anchor. | 你是最后的锚。 |
| —— Bring them home. | —— 带他们回家。 |

#### 通关界面（⚠️ 实际为简单显示/隐藏，见 completion_screen.tscn）

| 英文 | 中文 |
|------|------|
| The world is still broken. | 世界依旧破碎。 |
| But someone is still fighting. | 但还有人没有放弃。 |
| One anchor at a time. | 一枚锚，一枚锚地。 |
| You saved some of them. | 你拯救了一些人。 |
| —— Now they will save others. | —— 现在，他们会去拯救别人。 |
| Thank you for playing. | 感谢游玩。 |
| Return to title | 返回标题界面 |

#### 关卡衔接界面（⚠️ 实际仅显示编号+名称+目标，见 level_select.gd）

| 关卡 | 名称 | 🆕 新机制 | 💡 提示 |
|:--:|------|------|------|
| 1 | 初次引导 | — | 用锚铺出一条路 |
| 2 | 巡逻警戒 | 巡逻敌人 | 观察敌人节奏，在窗口期投锚 |
| 3 | 争分夺秒 | 锚点耐久 | 边铺边走，别停下来 |
| 4 | 钥匙与门 | 上锁的门 | 先拿钥匙，再开路 |
| 5 | 最后希望 | 全部机制融合 | 你所学的，全用上 |

---

### 3.7 技术参数（建议）

| 参数 | 推荐值 |
|------|:--:|
| Godot 版本 | 4.6 |
| 渲染器 | Forward Plus (D3D12) |
| 窗口分辨率 | 1920 × 1080 |
| 缩放模式 | canvas_items + expand |

| 纹理过滤 | 高清素材，非像素风 |
| 玩家动画 | AnimatedSprite2D，非像素风 |
| 地面瓦片 | TileMapLayer，高清素材 |

---

## 四、Git 规范

- 分支命名：`feature/<描述>`（实际项目使用 `feature/core-gameplay`）
- Commit message：中文，"动词+内容"（如 "修复 Coin 层级结构"）
- 提交前：`git status` + `git diff` → 排除 `.godot/`、`.tmp/`、`export/` → 等确认后再 commit
- 不执行 `git reset`、`git clean`、`git push --force` 等高风险命令

---

## 五、参考链接

- [Anchor 创意脑暴（飞书文档）](https://fwc1lwm6891.feishu.cn/wiki/Ounow1nDiiBwk7kbsw5cb20DnYe)
- mini-survivor 项目：`C:\Users\Admin\Projects\mini-survivor`
- godot_demo 项目：`C:\Users\Admin\Projects\godot_demo`
- 土豆兄弟分辨率参考：内部 480×270，整数缩放到 1080p

---

> 最后更新：2026.07.04
