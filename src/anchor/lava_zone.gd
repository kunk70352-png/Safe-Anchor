@tool
## 岩浆区 — 阻挡NPC和玩家，锚点丢入则重生。
extends StaticBody2D

@export var zone_size: Vector2 = Vector2(200, 200):
	set(v):
		zone_size = v
		_update_shape()

# 同时检测锚点（锚点 DangerDetector 检测 layer 16）
@onready var anchor_area: Area2D = $AnchorDetector


func _ready() -> void:
	add_to_group("lava_zones")
	_update_shape()


func contains_point(point: Vector2) -> bool:
	var rect := Rect2(global_position, zone_size)
	return rect.has_point(point)


func _update_shape() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			var rect := RectangleShape2D.new()
			rect.size = zone_size
			child.shape = rect
	if anchor_area:
		for child in anchor_area.get_children():
			if child is CollisionShape2D:
				var rect := RectangleShape2D.new()
				rect.size = zone_size
				child.shape = rect