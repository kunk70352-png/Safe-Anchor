## 锚点基类 — 吸引/驱赶难民。可被玩家拾取回收。
class_name Anchor
extends Node2D

signal picked_up()

## 吸引半径（像素）
@export var attraction_radius: float = 150.0:
	set(v):
		attraction_radius = v
		_update_range_scale()
## 显示颜色
@export var anchor_color: Color = Color(0.2, 0.5, 1.0, 1.0):
	set(v):
		anchor_color = v
		if range_sprite:
			range_sprite.modulate = Color(v.r, v.g, v.b, 1.0)
## 每秒缩小像素，0=不缩小
@export var shrink_speed: float = 0.0
## 缩小下限（不小于此值）
@export var min_radius: float = 20.0
## 难民速度加成（正=加速，负=减速）
@export var speed_modifier: float = 0.0
## 驱赶模式（推开难民而非吸引）
@export var repel: bool = false
## 范围贴图中圆的真实直径（像素），用于校准显示
@export var range_tex_diameter: float = 128.0

var _pulse_time: float = 0.0
var initial_radius: float = 0.0
var _spawn_pos: Vector2

@onready var range_sprite: Sprite2D = $"RangeSprite"


func _ready() -> void:
	add_to_group("attraction_sources")
	initial_radius = attraction_radius
	_spawn_pos = global_position
	_pulse_time = randf() * TAU

	_update_range_scale()
	if range_sprite:
		range_sprite.modulate = Color(anchor_color.r, anchor_color.g, anchor_color.b, 1.0)

	# 确保 DangerDetector 存在（检测危险区和岩浆区）
	var detector: Area2D = $DangerDetector if has_node("DangerDetector") else null
	if detector:
		if not detector.area_entered.is_connected(_on_danger_entered):
			detector.area_entered.connect(_on_danger_entered)
	else:
		detector = Area2D.new()
		detector.name = "DangerDetector"
		detector.collision_layer = 1
		detector.collision_mask = 18
		detector.monitoring = true
		detector.monitorable = true
		var collision_shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		collision_shape.shape = circle
		detector.add_child(collision_shape)
		detector.area_entered.connect(_on_danger_entered)
		add_child(detector)


func _on_danger_entered(_area: Area2D) -> void:
	global_position = _spawn_pos
	attraction_radius = initial_radius


func _process(delta: float) -> void:
	_pulse_time += delta
	if shrink_speed > 0 and attraction_radius > min_radius:
		attraction_radius = maxf(attraction_radius - shrink_speed * delta, min_radius)
	if range_sprite:
		var base_scale := _get_range_scale()
		var pulse := 1.0 + sin(_pulse_time * 3.0) * 0.03
		range_sprite.scale = Vector2.ONE * base_scale * pulse


func pick_up() -> void:
	picked_up.emit()
	queue_free()


# ---- 范围显示 ----

func _get_range_scale() -> float:
	if not range_sprite or not range_sprite.texture:
		return 1.0
	var tex_size := range_tex_diameter
	return (attraction_radius * 2.0) / tex_size


func _update_range_scale() -> void:
	if range_sprite:
		var s := _get_range_scale()
		range_sprite.scale = Vector2(s, s)