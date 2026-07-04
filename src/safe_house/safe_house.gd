## 安全屋 — 地图上的永久建筑。吸引范围内的难民会向其寻路。
## 进入救援半径的难民视为"已救出"。
class_name SafeHouse
extends Node2D

## 吸引半径（像素）
@export var attraction_radius: float = 200.0:
	set(value):
		attraction_radius = value
		queue_redraw()
## 救援触发半径（像素）
@export var rescue_radius: float = 30.0

@onready var rescue_area: Area2D = $RescueArea
@onready var rescue_collision: CollisionShape2D = $RescueArea/CollisionShape2D


func _ready() -> void:
	add_to_group("attraction_sources")
	if rescue_collision and rescue_collision.shape is CircleShape2D:
		(rescue_collision.shape as CircleShape2D).radius = rescue_radius
	rescue_area.body_entered.connect(_on_body_entered_rescue)


func _on_body_entered_rescue(body: Node2D) -> void:
	if body is Refugee:
		body.rescue()


func _draw() -> void:
	draw_circle(Vector2.ZERO, attraction_radius, Color(0.0, 0.7, 0.0, 0.10))
	draw_arc(Vector2.ZERO, attraction_radius, 0, TAU, 64, Color(0.0, 0.8, 0.0, 0.3), 2.0)
	draw_arc(Vector2.ZERO, rescue_radius, 0, TAU, 32, Color.GREEN, 2.0)
	var half := 15.0
	draw_rect(Rect2(-half, -half, half * 2, half * 2), Color(0.2, 0.7, 0.2), true)
	var roof := PackedVector2Array([
		Vector2(-half - 5, -half),
		Vector2(half + 5, -half),
		Vector2(0, -half - 15),
	])
	draw_polygon(roof, PackedColorArray([Color(0.1, 0.5, 0.1), Color(0.1, 0.5, 0.1), Color(0.1, 0.5, 0.1)]))
