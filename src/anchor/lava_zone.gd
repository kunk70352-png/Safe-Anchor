@tool
## 岩浆区 — 阻挡NPC和玩家，锚点丢入则重生。
extends StaticBody2D

@export var zone_size: Vector2 = Vector2(200, 200):
	set(v):
		zone_size = v
		_update_shape()


func _ready() -> void:
	_update_shape()
	# 连接锚点检测信号（即使 DangerDetector 侧失效也能兜底）
	var anchor_detector := get_node_or_null("AnchorDetector")
	if anchor_detector and not anchor_detector.area_entered.is_connected(_on_anchor_area_entered):
		anchor_detector.area_entered.connect(_on_anchor_area_entered)


func _on_anchor_area_entered(area: Area2D) -> void:
	# DangerDetector 作为 Anchor 的子节点进入岩浆区
	var parent := area.get_parent()
	if parent is Anchor:
		parent.global_position = parent._spawn_pos
		parent.attraction_radius = parent.initial_radius


func _update_shape() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			var rect := RectangleShape2D.new()
			rect.size = zone_size
			child.shape = rect

	var anchor_detector := get_node_or_null("AnchorDetector")
	if anchor_detector:
		for child in anchor_detector.get_children():
			if child is CollisionShape2D:
				var rect := RectangleShape2D.new()
				rect.size = zone_size
				child.shape = rect
