## 安全屋 — 地图上的永久建筑。吸引范围内的难民会向其寻路。
## 进入救援半径的难民视为"已救出"。
class_name SafeHouse
extends Node2D

## 吸引半径（像素）
@export var attraction_radius: float = 200.0:
	set(value):
		attraction_radius = value
		_update_range_scale()
## 救援触发半径（像素）
@export var rescue_radius: float = 30.0

@onready var rescue_area: Area2D = $"RescueArea"
@onready var rescue_collision: CollisionShape2D = $"RescueArea/CollisionShape2D"
@onready var range_sprite: Sprite2D = $"RangeSprite"


func _ready() -> void:
	add_to_group("attraction_sources")
	if rescue_collision and rescue_collision.shape is CircleShape2D:
		(rescue_collision.shape as CircleShape2D).radius = rescue_radius
	rescue_area.body_entered.connect(_on_body_entered_rescue)
	_update_range_scale()


func _on_body_entered_rescue(body: Node2D) -> void:
	if body is Refugee:
		body.rescue()


func _get_range_scale() -> float:
	if not range_sprite or not range_sprite.texture:
		return 1.0
	var tex_size := range_sprite.texture.get_size().x  # 720
	return (attraction_radius * 2.0) / tex_size


func _update_range_scale() -> void:
	if range_sprite:
		var s := _get_range_scale()
		range_sprite.scale = Vector2(s, s)