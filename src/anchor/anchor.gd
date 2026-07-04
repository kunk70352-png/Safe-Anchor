## 锚点 — 玩家投掷的永久吸引点。可被玩家拾取回收。
class_name Anchor
extends Node2D

# ---- 信号 ----
signal picked_up()

# ---- 属性 ----
@export var attraction_radius: float = 150.0:
	set(value):
		attraction_radius = value
		queue_redraw()

var _pulse_time: float = 0.0


func _ready() -> void:
	add_to_group("attraction_sources")
	_pulse_time = randf() * TAU  # 随机初始相位，多个锚点不同步


func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()


## 被玩家拾取
func pick_up() -> void:
	picked_up.emit()
	queue_free()


func _draw() -> void:
	var pulse := 1.0 + sin(_pulse_time * 3.0) * 0.08
	var r := attraction_radius * pulse

	# 吸引范围
	draw_circle(Vector2.ZERO, r, Color(0.0, 0.4, 1.0, 0.08))

	# 十字标识
	var cross_size := 10.0 * pulse
	var blue := Color(0.2, 0.5, 1.0, 1.0)
	draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), blue, 3.0)
	draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), blue, 3.0)

	# 中心点
	draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
