## SafeHouse — 地图上的永久建筑。
## 吸引范围内的难民会向其寻路。
## 进入救援半径的难民视为"已救出"。
class_name SafeHouse
extends Node2D

# ---- 导出属性 ----
@export var attraction_radius: float = 200.0:
	set(value):
		attraction_radius = value
		queue_redraw()
@export var rescue_radius: float = 30.0

# ---- 节点引用 ----
@onready var rescue_area: Area2D = $RescueArea
@onready var rescue_collision: CollisionShape2D = $RescueArea/CollisionShape2D


func _ready() -> void:
	add_to_group("attraction_sources")

	# 配置救援区域大小
	if rescue_collision and rescue_collision.shape is CircleShape2D:
		(rescue_collision.shape as CircleShape2D).radius = rescue_radius

	# 连接救援检测信号
	rescue_area.body_entered.connect(_on_body_entered_rescue)


func _on_body_entered_rescue(body: Node2D) -> void:
	if body is Refugee:
		var refugee := body as Refugee
		refugee.rescue()


func _draw() -> void:
	# 吸引范围（半透明绿色）
	draw_circle(Vector2.ZERO, attraction_radius, Color(0.0, 0.8, 0.0, 0.08))
	# 救援半径轮廓
	draw_arc(Vector2.ZERO, rescue_radius, 0, TAU, 32, Color.GREEN, 2.0)
	# 房屋形状（绿色方块+三角形屋顶）
	var half := 15.0
	draw_rect(Rect2(-half, -half, half * 2, half * 2), Color(0.2, 0.7, 0.2), true)
	var roof := PackedVector2Array([
		Vector2(-half - 5, -half),
		Vector2(half + 5, -half),
		Vector2(0, -half - 15),
	])
	draw_polygon(roof, PackedColorArray([Color(0.1, 0.5, 0.1), Color(0.1, 0.5, 0.1), Color(0.1, 0.5, 0.1)]))
