@tool
## 危险区 — NPC进入即死亡。对玩家和锚点无影响。
extends Area2D

@export var zone_radius: float = 100.0:
	set(v):
		zone_radius = v
		_update_shape()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_shape()


func _update_shape() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			var circle := CircleShape2D.new()
			circle.radius = zone_radius
			child.shape = circle


func _on_body_entered(body: Node2D) -> void:
	if body is Refugee:
		body.die()
