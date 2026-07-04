## 锚点基类 — 吸引/驱赶难民。可被玩家拾取回收。
class_name Anchor
extends Node2D

signal picked_up()

## 吸引半径（像素）
@export var attraction_radius: float = 150.0:
	set(v):
		attraction_radius = v
		queue_redraw()
## 显示颜色
@export var anchor_color: Color = Color(0.2, 0.5, 1.0, 1.0)
## 每秒缩小像素（0=不缩小）
@export var shrink_speed: float = 0.0
## 缩小下限（不小于此值）
@export var min_radius: float = 20.0
## 难民速度加成（正=加速，负=减速）
@export var speed_modifier: float = 0.0
## 驱赶模式（推走难民而非吸引）
@export var repel: bool = false

var _pulse_time: float = 0.0
var initial_radius: float = 0.0


func _ready() -> void:
	add_to_group("attraction_sources")
	initial_radius = attraction_radius
	_pulse_time = randf() * TAU


func _process(delta: float) -> void:
	_pulse_time += delta
	if shrink_speed > 0 and attraction_radius > min_radius:
		attraction_radius = maxf(attraction_radius - shrink_speed * delta, min_radius)
	queue_redraw()


func pick_up() -> void:
	picked_up.emit()
	queue_free()


func _draw() -> void:
	var c := anchor_color
	draw_circle(Vector2.ZERO, attraction_radius, Color(c.r, c.g, c.b, 0.10))
	draw_arc(Vector2.ZERO, attraction_radius, 0, TAU, 64, Color(c.r, c.g, c.b, 0.25), 1.5)

	var pulse := 1.0 + sin(_pulse_time * 3.0) * 0.05
	var glow_r := attraction_radius * pulse
	draw_arc(Vector2.ZERO, glow_r, _pulse_time * 2.0, _pulse_time * 2.0 + PI, 32, Color(c.r, c.g, c.b, 0.15), 2.0)

	var cross_size := 10.0
	draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), c, 3.0)
	draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), c, 3.0)
	draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
