## 移动安全屋 — 沿 Path2D 移动（仿照矿车），超出地图则失败。
class_name MovingSafeHouse
extends PathFollow2D

@export var speed: float = 60.0
@export var attraction_radius: float = 200.0:
	set(v):
		attraction_radius = v
		_update_range_scale()
@export var range_tex_diameter: float = 720.0

@onready var rescue_area: Area2D = $SafeHouseBody/RescueArea
@onready var range_sprite: Sprite2D = $SafeHouseBody/RangeSprite


func _ready() -> void:
	add_to_group("attraction_sources")
	if rescue_area:
		rescue_area.body_entered.connect(_on_body_entered_rescue)
	_update_range_scale()


func _physics_process(delta: float) -> void:
	progress += speed * delta

	# 超出地图边界 → 失败
	var pos := global_position
	if pos.x < -50 or pos.x > 1970 or pos.y < -50 or pos.y > 1130:
		var stats := {"level": 0, "level_name": "安全屋丢失"}
		if GameManager.current_level_data:
			stats = {"level": GameManager.current_level_data.level_number, "level_name": GameManager.current_level_data.level_name}
		GameManager.level_failed.emit(stats)


func _on_body_entered_rescue(body: Node2D) -> void:
	if body is Refugee:
		body.rescue()


func _get_range_scale() -> float:
	if not range_sprite or not range_sprite.texture:
		return 1.0
	return (attraction_radius * 2.0) / range_tex_diameter


func _update_range_scale() -> void:
	if range_sprite:
		var s := _get_range_scale()
		range_sprite.scale = Vector2(s, s)
