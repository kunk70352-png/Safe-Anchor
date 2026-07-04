## LevelData — 定义单个关卡所有参数的自定义资源。
class_name LevelData
extends Resource

## 关卡序号
@export var level_number: int = 1
## 关卡名称
@export var level_name: String = "Level 1"
## 需要救出的难民目标数
@export var target_rescued: int = 5
## 时间限制（秒）
@export var time_limit: float = 60.0
## 生成的难民数量
@export var refugee_count: int = 8
## 难民徘徊速度
@export var refugee_wander_speed: float = 60.0
## 难民被吸引速度
@export var refugee_seek_speed: float = 100.0
## 难民改变徘徊方向间隔（秒）
@export var refugee_wander_interval: float = 2.0
## 难民生成位置列表
@export var refugee_spawn_positions: Array[Vector2] = []
## 玩家锚点数量上限
@export var anchor_limit: int = 3
## 玩家锚点吸引半径
@export var anchor_attraction_radius: float = 150.0
## 安全屋位置
@export var safe_house_position: Vector2 = Vector2(960, 540)
## 安全屋吸引半径
@export var safe_house_attraction_radius: float = 200.0
## 锚点类型（扩展用）
@export var anchor_type: String = "default"
## 全局难度倍率
@export var difficulty_modifier: float = 1.0
## 自定义地图场景（扩展用）
@export var tile_map_scene: PackedStringArray = []
