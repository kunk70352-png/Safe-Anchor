@tool
## 危险区 — NPC进入即死亡。对玩家无影响。
extends Area2D

@export var zone_size: Vector2 = Vector2(200, 200):
	set(v):
		zone_size = v
		_update_shape()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_shape()


func _update_shape() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			var rect := RectangleShape2D.new()
			rect.size = zone_size
			child.shape = rect


func _on_body_entered(body: Node2D) -> void:
	if body is Refugee:
		body.die()
