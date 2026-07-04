## 玩家 — 可操控角色，WASD移动，空格蓄力投掷锚点。
class_name Player
extends CharacterBody2D

# ---- 状态 ----
enum PlayerState { IDLE, CHARGING }
var state: PlayerState = PlayerState.IDLE
var has_anchor: bool = true
var charge_time: float = 0.0
var charge_power: float = 0.0
var last_move_dir: Vector2 = Vector2.RIGHT

# ---- 参数 ----
@export var move_speed: float = 200.0
@export var anchor_radius: float = 160.0
const MIN_THROW: float = 80.0
const MAX_THROW: float = 350.0
const CHARGE_SPEED: float = 2.5
const CURVE_HEIGHT: float = 40.0

# ---- 节点 ----
@onready var pickup_area: Area2D = $PickupArea
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("player")
	pickup_area.body_entered.connect(_on_pickup_body_entered)


func _physics_process(delta: float) -> void:
	# 移动
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		last_move_dir = input_dir
	velocity = input_dir * move_speed
	move_and_slide()

	# 蓄力
	match state:
		PlayerState.IDLE:
			if has_anchor and Input.is_action_just_pressed("charge_throw"):
				state = PlayerState.CHARGING
				charge_time = 0.0
		PlayerState.CHARGING:
			charge_time += delta
			charge_power = (sin(charge_time * CHARGE_SPEED * TAU) + 1.0) / 2.0
			if Input.is_action_just_released("charge_throw"):
				_throw_anchor()
				state = PlayerState.IDLE
			elif not has_anchor:
				state = PlayerState.IDLE

	queue_redraw()


# ---- 投掷 ----

func _throw_anchor() -> void:
	var dist := MIN_THROW + charge_power * (MAX_THROW - MIN_THROW)
	var landing_pos := global_position + last_move_dir * dist

	var anchor_scene := preload("res://src/anchor/anchor.tscn")
	var anchor: Anchor = anchor_scene.instantiate()
	anchor.global_position = landing_pos
	anchor.attraction_radius = anchor_radius
	anchor.picked_up.connect(_on_anchor_picked_up)
	get_tree().get_first_node_in_group("world").get_node("Anchors").add_child(anchor)
	has_anchor = false


# ---- 拾取 ----

func _on_pickup_body_entered(body: Node2D) -> void:
	if has_anchor:
		return
	if body is Anchor:
		body.pick_up()


func _on_anchor_picked_up() -> void:
	has_anchor = true


# ---- 绘制预览 ----

func _draw() -> void:
	if state != PlayerState.CHARGING or not has_anchor:
		return

	var dist := MIN_THROW + charge_power * (MAX_THROW - MIN_THROW)
	var target := last_move_dir * dist
	var mid := target * 0.5 + Vector2.UP * CURVE_HEIGHT  # 贝塞尔控制点（向上拱起）

	# 抛物线轨迹
	var color := Color(1.0, 0.8, 0.2, 0.7)
	var steps := 20
	for i in range(steps):
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		var p0 := _bezier(Vector2.ZERO, mid, target, t0)
		var p1 := _bezier(Vector2.ZERO, mid, target, t1)
		draw_line(p0, p1, color, 2.0)

	# 落点范围圈
	draw_circle(target, anchor_radius, Color(0.2, 0.5, 1.0, 0.12))
	draw_arc(target, anchor_radius, 0, TAU, 32, Color(0.2, 0.5, 1.0, 0.4), 1.5)

	# 蓄力条（玩家下方）
	var bar_width := 40.0
	var bar_height := 4.0
	var bar_y := 20.0
	var bg_rect := Rect2(-bar_width / 2, bar_y, bar_width, bar_height)
	draw_rect(bg_rect, Color(0.2, 0.2, 0.2, 0.8))
	var fill_rect := Rect2(-bar_width / 2, bar_y, bar_width * charge_power, bar_height)
	draw_rect(fill_rect, Color(1.0, 0.8, 0.2, 1.0))


func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)
