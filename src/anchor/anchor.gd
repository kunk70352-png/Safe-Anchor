## Anchor — 玩家放置的吸引点。
## 吸引范围内的难民。有可配置的生命周期，到期自动销毁。
class_name Anchor
extends Node2D

# ---- 信号 ----
signal lifetime_expired(anchor: Anchor)

# ---- 导出属性 ----
@export var attraction_radius: float = 150.0:
	set(value):
		attraction_radius = value
		queue_redraw()
@export var lifetime: float = 300.0

# ---- 内部状态 ----
var _pulse_time: float = 0.0
var _remaining_lifetime: float = 0.0

# ---- 节点引用 ----
@onready var _timer: Timer = $LifetimeTimer


func _ready() -> void:
	add_to_group("attraction_sources")

	# 配置并启动生命周期计时器
	_timer.wait_time = lifetime
	_timer.one_shot = true
	_timer.timeout.connect(_on_lifetime_expired)
	_timer.start()
	_remaining_lifetime = lifetime


func _process(delta: float) -> void:
	_pulse_time += delta
	_remaining_lifetime = _timer.time_left
	queue_redraw()


func _on_lifetime_expired() -> void:
	lifetime_expired.emit(self)
	GameManager.remove_anchor()
	queue_free()


func _draw() -> void:
	# 脉冲效果：半径轻微震荡
	var pulse := 1.0 + sin(_pulse_time * 3.0) * 0.08
	var r := attraction_radius * pulse

	# 吸引范围（半透明蓝色，脉冲）
	draw_circle(Vector2.ZERO, r, Color(0.0, 0.4, 1.0, 0.08))

	# 锚点十字标识（蓝底白字）
	var cross_size := 10.0 * pulse
	var blue := Color(0.2, 0.5, 1.0, 1.0)
	draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), blue, 3.0)
	draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), blue, 3.0)

	# 中心点
	draw_circle(Vector2.ZERO, 4.0, Color.WHITE)

	# 倒计时环（随时间流逝而缩短的圆弧）
	if lifetime > 0:
		var fraction := _remaining_lifetime / lifetime
		var start_angle := -PI / 2.0
		var end_angle := start_angle + TAU * fraction
		draw_arc(Vector2.ZERO, 14.0, start_angle, end_angle, 32, Color.WHITE, 2.0)
