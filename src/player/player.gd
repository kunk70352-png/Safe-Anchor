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
const CHARGE_SPEED: float = 0.8
const CURVE_HEIGHT: float = 40.0
const PICKUP_DIST: float = 30.0


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	# 移动
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		last_move_dir = input_dir
	velocity = input_dir * move_speed
	move_and_slide()

	# 拾取检测
	if not has_anchor:
		_check_pickup()

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
	landing_pos = landing_pos.clamp(Vector2(40, 40), Vector2(1240, 680))

	var anchor_scene := preload("res://src/anchor/anchor.tscn")
	var anchor: Anchor = anchor_scene.instantiate()
	anchor.global_position = landing_pos
	anchor.attraction_radius = anchor_radius
	anchor.picked_up.connect(_on_anchor_picked_up)
	get_tree().get_first_node_in_group("world").get_node("Anchors").add_child(anchor)
	has_anchor = false


# ---- 拾取 ----

func _check_pickup() -> void:
	var world := get_tree().get_first_node_in_group("world")
	if not world:
		return
	var anchors := world.get_node("Anchors")
	for anchor in anchors.get_children():
		if global_position.distance_to(anchor.global_position) < PICKUP_DIST:
			anchor.pick_up()
			break


func _on_anchor_picked_up() -> void:
	has_anchor = true


# ---- 绘制预览 ----

func _draw() -> void:
	# 玩家身体（橙色方块）
	var half := 10.0
	draw_rect(Rect2(-half, -half, half * 2, half * 2), Color.ORANGE, true)
	# 持有锚点时显示小蓝点
	if has_anchor:
		draw_circle(Vector2(0, -half - 4), 3.0, Color.DODGER_BLUE)

	# 蓄力预览
	if state != PlayerState.CHARGING or not has_anchor:
		return

	var dist := MIN_THROW + charge_power * (MAX_THROW - MIN_THROW)
	var target := last_move_dir * dist
	var mid := target * 0.5 + Vector2.UP * CURVE_HEIGHT

	# 抛物线
	var line_color := Color(1.0, 0.8, 0.2, 0.7)
	var steps := 20
	for i in range(steps):
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		draw_line(_bezier(Vector2.ZERO, mid, target, t0), _bezier(Vector2.ZERO, mid, target, t1), line_color, 2.0)

	# 落点范围圈
	draw_circle(target, anchor_radius, Color(0.2, 0.5, 1.0, 0.12))
	draw_arc(target, anchor_radius, 0, TAU, 32, Color(0.2, 0.5, 1.0, 0.4), 1.5)

	# 蓄力条
	var bar_w := 40.0
	var bar_h := 4.0
	var bar_y := 22.0
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2, 0.8))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * charge_power, bar_h), Color(1.0, 0.8, 0.2, 1.0))


func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)
