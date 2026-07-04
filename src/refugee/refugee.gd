## 难民 — AI 控制角色，被锚点/安全屋吸引前随机徘徊。
class_name Refugee
extends CharacterBody2D

enum State { WANDERING, SEEKING, RESCUED }

@export var wander_speed: float = 60.0
@export var seek_speed: float = 100.0
@export var wander_interval: float = 2.0
@export var wander_origin: Vector2
@export var anchor_slow_mult: float = 0.4
@export var anchor_wander_angle: float = 0.4
@export var anchor_wander_min: float = 0.1
@export var anchor_wander_max: float = 0.4

var state: State = State.WANDERING
var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _current_attractor: Node2D = null
var _speed_mult: float = 1.0
var _speed_boost: float = 1.0
var _range_boost: float = 0.0
var _repel_dir: Vector2 = Vector2.ZERO

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("refugees")
	navigation_agent.path_desired_distance = 8.0
	navigation_agent.target_desired_distance = 8.0
	navigation_agent.avoidance_enabled = false
	_setup_navigation.call_deferred()


func _setup_navigation() -> void:
	await get_tree().physics_frame
	_pick_new_wander_target()


func _physics_process(_delta: float) -> void:
	if state == State.RESCUED:
		return
	_update_state()
	_process_movement()
	_update_animation()
	_apply_anchor_effects()


func _update_state() -> void:
	var best := _find_best_target()

	if best == null:
		state = State.WANDERING
		_current_attractor = null
		if navigation_agent.is_navigation_finished():
			_pick_new_wander_target()
		return

	if best is SafeHouse:
		_navigate_to(best)
		return

	var sh := _get_safe_house_node()
	if sh:
		var anchor_r: float = float(best.get("attraction_radius"))
		var sh_r := _get_safe_house_radius()
		if best.global_position.distance_to(sh.global_position) <= anchor_r + sh_r:
			_navigate_to(sh)
			return

	if best != _current_attractor:
		_navigate_to(best)
	elif navigation_agent.is_navigation_finished():
		_wander_near_anchor(best)


func _navigate_to(target: Node2D) -> void:
	state = State.SEEKING
	_current_attractor = target
	_speed_mult = 1.0
	navigation_agent.target_position = target.global_position


func _wander_near_anchor(anchor: Node2D) -> void:
	state = State.WANDERING
	var radius: float = float(anchor.get("attraction_radius"))
	var sh_pos := _get_safe_house_pos()
	var base_dir := (anchor.global_position - sh_pos).normalized()
	var angle := randf_range(-PI * anchor_wander_angle, PI * anchor_wander_angle)
	var dist := randf_range(radius * anchor_wander_min, radius * anchor_wander_max)
	_speed_mult = anchor_slow_mult
	navigation_agent.target_position = anchor.global_position + base_dir.rotated(angle) * dist


func _find_best_target() -> Node2D:
	var world := get_tree().get_first_node_in_group("world") as Node2D
	if world == null or not world.has_method("get_attraction_sources"):
		return null

	var sources: Array[Node2D] = world.get_attraction_sources()
	if sources.is_empty():
		return null

	var sh_pos := _get_safe_house_pos()
	var best: Node2D = null
	var best_sh_dist: float = INF

	for source in sources:
		if not is_instance_valid(source):
			continue
		var dist_to_me := global_position.distance_to(source.global_position)
		var radius: float = float(source.get("attraction_radius")) + _range_boost
		if dist_to_me > radius:
			continue
		if source is SafeHouse:
			return source
		var dist_to_sh := source.global_position.distance_to(sh_pos)
		if dist_to_sh < best_sh_dist:
			best_sh_dist = dist_to_sh
			best = source

	return best


func _apply_anchor_effects() -> void:
	var total_speed_mod: float = 0.0
	_range_boost = 0.0
	_repel_dir = Vector2.ZERO
	var world := get_tree().get_first_node_in_group("world") as Node2D
	if world == null or not world.has_method("get_attraction_sources"):
		return
	for source in world.get_attraction_sources():
		if not is_instance_valid(source):
			continue
		var dist := global_position.distance_to(source.global_position)
		var radius: float = float(source.get("attraction_radius"))
		if dist <= radius:
			var sm: float = source.get("speed_modifier") if source.get("speed_modifier") != null else 0.0
			total_speed_mod += sm
			if source.get("repel") == true:
				_repel_dir += (global_position - source.global_position).normalized()
			if source.get("repel") != true and float(source.get("attraction_radius")) > 200:
				_range_boost = maxf(_range_boost, 60.0)
	_speed_boost = maxf(1.0 + total_speed_mod, 0.1)


func _get_safe_house_pos() -> Vector2:
	var world := get_tree().get_first_node_in_group("world") as Node2D
	if world and world.has_method("get_safe_house_position"):
		return world.get_safe_house_position()
	return Vector2.ZERO


func _get_safe_house_radius() -> float:
	var world := get_tree().get_first_node_in_group("world") as Node2D
	if world and world.has_method("get_safe_house_radius"):
		return world.get_safe_house_radius()
	return 200.0


func _get_safe_house_node() -> Node2D:
	var world := get_tree().get_first_node_in_group("world") as Node2D
	if world and world.has_method("get_safe_house_node"):
		return world.get_safe_house_node()
	return null


func _process_movement() -> void:
	if state == State.SEEKING and _repel_dir != Vector2.ZERO:
		# 驱赶优先：朝远离锚点方向移动
		var speed := seek_speed * _speed_boost
		velocity = _repel_dir * speed
		move_and_slide()
		return
	if navigation_agent.is_navigation_finished():
		return
	var next_pos := navigation_agent.get_next_path_position()
	var speed := seek_speed if state == State.SEEKING else wander_speed
	velocity = global_position.direction_to(next_pos) * speed * _speed_mult * _speed_boost
	move_and_slide()


func _update_animation() -> void:
	if not sprite:
		return
	var moving := velocity.length() > 10.0
	if not moving:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
		else:
			sprite.stop()
	elif state == State.SEEKING:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("run"):
			sprite.play("run")
	elif sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")
	if absf(velocity.x) > 10.0:
		sprite.flip_h = velocity.x < 0


func _pick_new_wander_target() -> void:
	var angle := randf() * TAU
	var dist := randf() * 120.0 + 40.0
	navigation_agent.target_position = wander_origin + Vector2.RIGHT.rotated(angle) * dist


func rescue() -> void:
	if state == State.RESCUED:
		return
	state = State.RESCUED
	GameManager.register_rescue()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(self.queue_free)
