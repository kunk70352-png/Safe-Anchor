## 危险区 — NPC 进入即死亡，关卡失败。
extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Refugee:
		body.die()
