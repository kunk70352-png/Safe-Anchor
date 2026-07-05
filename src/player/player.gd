## 玩家 — WASD移动，鼠标左键蓄力投掷锚点。
class_name Player
extends CharacterBody2D

enum PlayerState { IDLE, CHARGING }
var state: PlayerState = PlayerState.IDLE
var _held_anchor: PackedScene = null
var _held_anchor_radius: float = 0.0
var _held_anchor_color: Color = Color.WHITE
var _held_anchor_icon_tex: Texture2D = null
var _held_anchor_range_tex: Texture2D = null
var _held_anchor_range_tex_diameter: float = 128.0
var charge_time: float = 0.0
var charge_power: float = 0.0

@export var move_speed: float = 200.0
@export var anchor_data: AnchorData
@export var min_throw: float = 80.0
@export var max_throw: float = 350.0
@export var charge_speed: float = 0.8
@export var curve_height: float = 40.0
@export var pickup_dist: float = 30.0

var sprite: AnimatedSprite2D
var _last_pickup_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	sprite = $AnimatedSprite2D
	if not anchor_data:
		anchor_data = load("res://resources/default_anchor.tres")

func _physics_process(delta: float) -> void:
	if not GameManager.is_level_active:
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * move_speed
	move_and_slide()

	if _held_anchor == null:
		_check_pickup()

	match state:
		PlayerState.IDLE:
			if _held_anchor != null and Input.is_action_just_pressed("charge_throw"):
				state = PlayerState.CHARGING
				charge_time = 0.0
				_play_charge_sfx()
		PlayerState.CHARGING:
			charge_time += delta
			charge_power = (sin(charge_time * charge_speed * TAU) + 1.0) / 2.0
			if Input.is_action_just_released("charge_throw"):
				_stop_charge_sfx()
				_throw_anchor()
				state = PlayerState.IDLE
			elif _held_anchor == null:
				_stop_charge_sfx()
				state = PlayerState.IDLE

	queue_redraw()


func _throw_anchor() -> void:
	if _held_anchor == null:
		return
	var mouse_pos := get_global_mouse_position()
	var throw_dir := (mouse_pos - global_position).normalized()
	var dist := min_throw + charge_power * (max_throw - min_throw)
	var landing_pos := global_position + throw_dir * dist
	landing_pos = landing_pos.clamp(Vector2(40, 40), Vector2(1880, 1040))

	# 落点在岩浆内 → 取消投掷
	for zone in get_tree().get_nodes_in_group("lava_zones"):
		if zone.has_method("contains_point") and zone.contains_point(landing_pos):
			return
	
	var anchor: Anchor = _held_anchor.instantiate()
	anchor.global_position = landing_pos
	anchor.attraction_radius = _held_anchor_radius
	anchor.picked_up.connect(_on_anchor_picked_up)
	get_tree().get_first_node_in_group("world").get_node("Anchors").add_child(anchor)
	# 覆盖 _ready() 中设置的 _spawn_pos，使锚点重生时回到捡起位置
	if _last_pickup_pos != Vector2.ZERO:
		anchor._spawn_pos = _last_pickup_pos
	_held_anchor = null
	_held_anchor_radius = 0.0
	_held_anchor_icon_tex = null
	_held_anchor_range_tex = null
	AudioManager.play_sfx(load("res://assets/audio/throw.mp3"))


func _check_pickup() -> void:
	var world := get_tree().get_first_node_in_group("world")
	if not world:
		return
	var anchors := world.get_node("Anchors")
	for a in anchors.get_children():
		if global_position.distance_to(a.global_position) < pickup_dist:
			_pickup_anchor(a)
			return

	# 也检查矿车上的锚点
	for cart in get_tree().get_nodes_in_group("minecarts"):
		if not cart.has_method("get_caught_anchor"):
			continue
		var a: Anchor = cart.get_caught_anchor()
		if a and is_instance_valid(a) and global_position.distance_to(a.global_position) < pickup_dist:
			cart.release_anchor()
			_pickup_anchor(a)
			return


func _pickup_anchor(a: Anchor) -> void:
	if not a.picked_up.is_connected(_on_anchor_picked_up):
		a.picked_up.connect(_on_anchor_picked_up)
	_held_anchor = load(a.scene_file_path)
	_last_pickup_pos = a.global_position
	_held_anchor_radius = float(a.get("initial_radius")) if a.get("initial_radius") != null else float(a.get("attraction_radius"))
	_held_anchor_color = a.get("anchor_color") if a.get("anchor_color") != null else Color(0.2, 0.5, 1.0, 1.0)

	# 提取锚点本体贴图
	var icon_sprite := a.get_node("Sprite2D")
	if icon_sprite and icon_sprite.texture:
		_held_anchor_icon_tex = icon_sprite.texture

	# 提取范围贴图及校准参数
	var range_sprite := a.get_node("RangeSprite")
	if range_sprite and range_sprite.texture:
		_held_anchor_range_tex = range_sprite.texture
	var diameter = a.get("range_tex_diameter")
	if diameter != null:
		_held_anchor_range_tex_diameter = float(diameter)

	a.pick_up()
	AudioManager.play_sfx(load("res://assets/audio/pickup.mp3"))


func _on_anchor_picked_up() -> void:
	pass


func _update_animation() -> void:
	if not sprite:
		return
	var moving := velocity.length() > 10.0
	if state == PlayerState.CHARGING:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("charge"):
			sprite.play("charge")
	elif moving:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")
	else:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
	if absf(velocity.x) > 10.0:
		sprite.flip_h = velocity.x < 0


# ---- 绘制 ----

func _draw() -> void:
	if _held_anchor == null:
		return

	match state:
		PlayerState.IDLE:
			# 头顶锚点贴图
			if _held_anchor_icon_tex:
				var tex_size := _held_anchor_icon_tex.get_size()
				draw_texture(_held_anchor_icon_tex, Vector2(-tex_size.x / 2, -28 - tex_size.y))

		PlayerState.CHARGING:
			# 蓄力条
			var bar_w := 40.0
			var bar_h := 4.0
			var bar_y := 22.0
			draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2, 0.8))
			draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * charge_power, bar_h), Color(1.0, 0.8, 0.2, 1.0))

			# 抛物线轨迹
			var mouse_pos := get_global_mouse_position()
			var throw_dir := (mouse_pos - global_position).normalized()
			var dist := min_throw + charge_power * (max_throw - min_throw)
			var target := throw_dir * dist
			var mid := target * 0.5 + Vector2.UP * curve_height

			var line_color := Color(1.0, 0.8, 0.2, 0.7)
			var steps := 20
			for i in range(steps):
				var t0 := float(i) / steps
				var t1 := float(i + 1) / steps
				draw_line(_bezier(Vector2.ZERO, mid, target, t0), _bezier(Vector2.ZERO, mid, target, t1), line_color, 2.0)

			# 落点锚点贴图
			if _held_anchor_icon_tex:
				var icon_size := _held_anchor_icon_tex.get_size()
				draw_texture(_held_anchor_icon_tex, target - icon_size * 0.5)

			# 落点范围贴图
			if _held_anchor_range_tex:
				var tex_size := _held_anchor_range_tex.get_size()
				var scale := (_held_anchor_radius * 2.0) / _held_anchor_range_tex_diameter
				var draw_size := tex_size * scale
				var c := _held_anchor_color
				draw_texture_rect(_held_anchor_range_tex, Rect2(target - draw_size * 0.5, draw_size), false, Color(c.r, c.g, c.b, 0.4))


# ---- 音效 ----

var _charge_sfx_player: AudioStreamPlayer

func _play_charge_sfx() -> void:
	if not _charge_sfx_player:
		_charge_sfx_player = AudioStreamPlayer.new()
		add_child(_charge_sfx_player)
	var s := load("res://assets/audio/charge.mp3")
	if s:
		_charge_sfx_player.stream = s
		_charge_sfx_player.play()


func _stop_charge_sfx() -> void:
	if _charge_sfx_player and _charge_sfx_player.playing:
		_charge_sfx_player.stop()


func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)
