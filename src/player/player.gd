## 玩家 — 可操控角色，WASD移动，空格蓄力投掷锚点。
class_name Player
extends CharacterBody2D

enum PlayerState { IDLE, CHARGING }
var state: PlayerState = PlayerState.IDLE
var _held_anchor: PackedScene = preload("res://src/anchor/anchor_type1.tscn")
var _held_anchor_radius: float = 180.0
var charge_time: float = 0.0
var charge_power: float = 0.0
var last_move_dir: Vector2 = Vector2.RIGHT

## 移动速度（像素/秒）
@export var move_speed: float = 200.0
## 默认锚点数据资源
@export var anchor_data: AnchorData
## 投掷最近距离（像素）
@export var min_throw: float = 80.0
## 投掷最远距离（像素）
@export var max_throw: float = 350.0
## 蓄力条摆动速度（次/秒）
@export var charge_speed: float = 0.8
## 抛物线预览高度（像素）
@export var curve_height: float = 40.0
## 拾取锚点距离（像素）
@export var pickup_dist: float = 30.0


func _ready() -> void:
	add_to_group("player")
	if not anchor_data:
		anchor_data = load("res://resources/default_anchor.tres")


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		last_move_dir = input_dir
	velocity = input_dir * move_speed
	move_and_slide()

	if _held_anchor == null:
		_check_pickup()

	match state:
		PlayerState.IDLE:
			if _held_anchor != null and Input.is_action_just_pressed("charge_throw"):
				state = PlayerState.CHARGING
				charge_time = 0.0
		PlayerState.CHARGING:
			charge_time += delta
			charge_power = (sin(charge_time * charge_speed * TAU) + 1.0) / 2.0
			if Input.is_action_just_released("charge_throw"):
				_throw_anchor()
				state = PlayerState.IDLE
			elif _held_anchor == null:
				state = PlayerState.IDLE

	queue_redraw()


func _throw_anchor() -> void:
	var dist := min_throw + charge_power * (max_throw - min_throw)
	var landing_pos := global_position + last_move_dir * dist
	landing_pos = landing_pos.clamp(Vector2(40, 40), Vector2(1880, 1040))

	var anchor: Anchor = _held_anchor.instantiate()
	anchor.global_position = landing_pos
	anchor.picked_up.connect(_on_anchor_picked_up)
	get_tree().get_first_node_in_group("world").get_node("Anchors").add_child(anchor)
	_held_anchor = null
	_held_anchor_radius = 0.0


func _check_pickup() -> void:
	var world := get_tree().get_first_node_in_group("world")
	if not world:
		return
	var anchors := world.get_node("Anchors")
	for a in anchors.get_children():
		if global_position.distance_to(a.global_position) < pickup_dist:
			if not a.picked_up.is_connected(_on_anchor_picked_up):
				a.picked_up.connect(_on_anchor_picked_up)
			_held_anchor = load(a.scene_file_path)
			_held_anchor_radius = float(a.get("attraction_radius"))
			a.pick_up()
			break


func _on_anchor_picked_up() -> void:
	pass


func _draw() -> void:
	var half := 10.0
	draw_rect(Rect2(-half, -half, half * 2, half * 2), Color.ORANGE, true)
	if _held_anchor != null:
		draw_circle(Vector2(0, -half - 4), 3.0, Color.DODGER_BLUE)

	if state != PlayerState.CHARGING or _held_anchor == null:
		return

	var dist := min_throw + charge_power * (max_throw - min_throw)
	var target := last_move_dir * dist
	var mid := target * 0.5 + Vector2.UP * curve_height

	var line_color := Color(1.0, 0.8, 0.2, 0.7)
	var steps := 20
	for i in range(steps):
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		draw_line(_bezier(Vector2.ZERO, mid, target, t0), _bezier(Vector2.ZERO, mid, target, t1), line_color, 2.0)

	draw_circle(target, _held_anchor_radius, Color(0.2, 0.5, 1.0, 0.12))
	draw_arc(target, _held_anchor_radius, 0, TAU, 32, Color(0.2, 0.5, 1.0, 0.4), 1.5)

	var bar_w := 40.0
	var bar_h := 4.0
	var bar_y := 22.0
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2, 0.8))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * charge_power, bar_h), Color(1.0, 0.8, 0.2, 1.0))


func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)
