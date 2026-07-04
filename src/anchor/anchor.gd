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

var _pulse_time: float = 0.0
var initial_radius: float = 0.0
var _spawn_pos: Vector2

@onready var range_sprite: Sprite2D = $"RangeSprite"


func _ready() -> void:
	add_to_group("attraction_sources")
	initial_radius = attraction_radius
	_spawn_pos = global_position
	_pulse_time = randf() * TAU

	# 调试：检查 RangeSprite 状态
	if not range_sprite:
		print_debug("[Anchor] RangeSprite 节点未找到！检查场景中是否有名为 RangeSprite 的子节点")
	elif not range_sprite.texture:
		print_debug("[Anchor] RangeSprite 纹理为空！检查 anchor.png 是否导入")
	else:
		print_debug("[Anchor] RangeSprite OK, tex=", range_sprite.texture.get_size(), " radius=", attraction_radius)

	_update_range_scale()
	if range_sprite:
		range_sprite.modulate = Color(anchor_color.r, anchor_color.g, anchor_color.b, 1.0)
	if has_node("DangerDetector"):
		$DangerDetector.area_entered.connect(_on_danger_entered)


func _on_danger_entered(_area: Area2D) -> void:
	global_position = _spawn_pos
	attraction_radius = initial_radius


func _process(delta: float) -> void:
	_pulse_time += delta
	if shrink_speed > 0 and attraction_radius > min_radius:
		attraction_radius = maxf(attraction_radius - shrink_speed * delta, min_radius)
	# 呼吸脉冲 + 缩放更新
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
	var tex_size := range_sprite.texture.get_size().x  # 128
	return (attraction_radius * 2.0) / tex_size


func _update_range_scale() -> void:
	if range_sprite:
		var s := _get_range_scale()
		range_sprite.scale = Vector2(s, s)
