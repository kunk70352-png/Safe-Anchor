## 难民 — AI 控制角色，被锚点/安全屋吸引前随机徘徊。
class_name Refugee
extends CharacterBody2D

enum State { WANDERING, SEEKING, RESCUED }

## 随机徘徊移动速度（像素/秒）
@export var wander_speed: float = 60.0
## 被吸引时移动速度（像素/秒）
@export var seek_speed: float = 100.0
## 改变徘徊方向的间隔（秒）
@export var wander_interval: float = 2.0
## 初始徘徊中心点（由 World 设置）
@export var wander_origin: Vector2
## 徘徊范围限制（像素）
@export var wander_range: float = 300.0
## 锚点范围内减速倍率（0~1）
@export var anchor_slow_mult: float = 0.4
## 锚点范围内徘徊角度范围（0~1，1=180°）
@export var anchor_wander_angle: float = 0.4
## 锚点范围内徘徊最近距离（占半径比例）
@export var anchor_wander_min: float = 0.1
## 锚点范围内徘徊最远距离（占半径比例）
@export var anchor_wander_max: float = 0.4

var state: State = State.WANDERING
var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _current_attractor: Node2D = null
var _speed_mult: float = 1.0
var _speed_boost: float = 1.0
var _range_boost: float = 0.0
var _repel_dir: Vector2 = Vector2.ZERO
var _repel_timer: float = 0.0

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
		# 正在导航中途，不中断（锚点间隙保护）
		if state == State.SEEKING and not navigation_agent.is_navigation_finished():
			return
		state = State.WANDERING
		_current_attractor = null
		if navigation_agent.is_navigation_finished():
			_pick_new_wander_target()
		return

	var sh := _get_safe_house_node()
	if sh:
		var anchor_r: float = float(best.get("attraction_radius"))
		var sh_r := _get_safe_house_radius()
		if best.global_position.distance_to(sh.global_position) <= anchor_r + sh_r:
			_navigate_to(sh)
			return

	# 防止多锚点间抖动：新锚点必须明显更近才切换
	var should_switch := best != _current_attractor
	if should_switch and _current_attractor != null:
		var cur_d := _current_attractor.global_position.distance_to(sh.global_position)
		var new_d := best.global_position.distance_to(sh.global_position)
		should_switch = new_d < cur_d - 20.0

	if should_switch:
		_navigate_to(best)
	elif navigation_agent.is_navigation_finished():
		_advance_to_next_anchor(best)


func _navigate_to(target: Node2D) -> void:
	state = State.SEEKING
	_current_attractor = target
	_speed_mult = 1.0
	navigation_agent.target_position = target.global_position


func _advance_to_next_anchor(current: Node2D) -> void:
	var world := get_tree().get_first_node_in_group("world") as Node2D
	if world == null or not world.has_method("find_next_anchor_to_safehouse"):
		return

	var next_anchor = world.find_next_anchor_to_safehouse(current) as Node2D
	if next_anchor != null and next_anchor != current:
		_navigate_to(next_anchor)
		return

	# BFS 未找到路径 — 在范围内缓慢徘徊等待
	state = State.WANDERING
	var r: float = float(current.get("attraction_radius"))
	var angle := randf_range(-PI * anchor_wander_angle, PI * anchor_wander_angle)
	var dist := randf_range(r * anchor_wander_min, r * anchor_wander_max)
	navigation_agent.target_position = current.global_position + Vector2.RIGHT.rotated(angle) * dist
	_speed_mult = anchor_slow_mult


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
		if source.get("repel") == true:
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
			if source.get("repel") == true:
				_repel_dir += (global_position - source.global_position).normalized()
				_repel_timer = 0.6
			else:
				var sm: float = source.get("speed_modifier") if source.get("speed_modifier") != null else 0.0
				total_speed_mod += sm
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
	if _repel_timer > 0.0:
		_repel_timer -= get_physics_process_delta_time()
		var sh_pos := _get_safe_house_pos()
		var flee_target := global_position + _repel_dir * 300.0
		if sh_pos.distance_to(flee_target) > sh_pos.distance_to(global_position):
			navigation_agent.target_position = flee_target
		var next_pos := navigation_agent.get_next_path_position()
		velocity = global_position.direction_to(next_pos) * seek_speed * 1.3
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
	var dist := randf() * wander_range * 0.8
	navigation_agent.target_position = wander_origin + Vector2.RIGHT.rotated(angle) * dist


func rescue() -> void:
	if state == State.RESCUED:
		return
	state = State.RESCUED
	GameManager.register_rescue()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(self.queue_free)


## 进入危险区死亡，关卡失败
func die() -> void:
	if state == State.RESCUED:
		return
	state = State.RESCUED
	var stats := {
		"level": GameManager.current_level_data.level_number if GameManager.current_level_data else 0,
		"level_name": GameManager.current_level_data.level_name if GameManager.current_level_data else "",
	}
	GameManager.level_failed.emit(stats)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.3)
	tween.tween_callback(self.queue_free)
