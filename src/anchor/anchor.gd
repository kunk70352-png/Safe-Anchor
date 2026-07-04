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
	# 实际范围（与检测半径一致，不随脉冲变化）
	draw_circle(Vector2.ZERO, attraction_radius, Color(0.0, 0.4, 1.0, 0.10))
	draw_arc(Vector2.ZERO, attraction_radius, 0, TAU, 64, Color(0.3, 0.6, 1.0, 0.25), 1.5)

	# 脉冲效果（纯装饰，不影响实际范围）
	var pulse := 1.0 + sin(_pulse_time * 3.0) * 0.05
	var glow_r := attraction_radius * pulse
	draw_arc(Vector2.ZERO, glow_r, _pulse_time * 2.0, _pulse_time * 2.0 + PI, 32, Color(0.5, 0.7, 1.0, 0.15), 2.0)

	# 十字标识
	var cross_size := 10.0
	var blue := Color(0.2, 0.5, 1.0, 1.0)
	draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), blue, 3.0)
	draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), blue, 3.0)

	# 中心点
	draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
