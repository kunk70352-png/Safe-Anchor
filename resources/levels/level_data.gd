## LevelData — 定义单个关卡所有参数的自定义资源。
## 在 resources/levels/ 目录创建 .tres 文件来定义每个关卡。
## 等价于 Unity 的 ScriptableObject 或 Unreal 的 DataTable。
class_name LevelData
extends Resource

# ---- 关卡标识 ----
@export var level_number: int = 1
@export var level_name: String = "Level 1"

# ---- 胜负条件 ----
@export var target_rescued: int = 5          # 需要救出的难民数量
@export var time_limit: float = 60.0         # 倒计时（秒）

# ---- 难民配置 ----
@export var refugee_count: int = 8           # 关卡开始时生成的难民数量
@export var refugee_wander_speed: float = 60.0
@export var refugee_seek_speed: float = 100.0
@export var refugee_wander_interval: float = 2.0  # 改变徘徊方向的间隔（秒）
@export var refugee_spawn_positions: Array[Vector2] = []  # 难民生成位置

# ---- 锚点配置 ----
@export var anchor_limit: int = 3            # 玩家可放置的锚点上限
@export var anchor_attraction_radius: float = 150.0

# ---- 安全屋配置 ----
@export var safe_house_position: Vector2 = Vector2(640, 360)  # 1280x720 画面中心
@export var safe_house_attraction_radius: float = 200.0

# ---- 扩展预留（后续使用） ----
@export var anchor_type: String = "default"  # 后续锚点子类选择
@export var difficulty_modifier: float = 1.0 # 全局难度倍率
@export var tile_map_scene: PackedStringArray = []  # 自定义地图场景
