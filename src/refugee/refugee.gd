## Refugee — AI-controlled character that wanders until attracted by an anchor/safe house.
## Uses NavigationAgent2D for pathfinding. Implements a 3-state machine.
class_name Refugee
extends CharacterBody2D

# ---- State Machine ----
enum State { WANDERING, SEEKING, RESCUED }

# ---- Exported Properties ----
@export var wander_speed: float = 60.0
@export var seek_speed: float = 100.0
@export var wander_interval: float = 2.0
@export var wander_origin: Vector2

# ---- Internal State ----
var state: State = State.WANDERING
var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _current_attractor: Node2D = null

# ---- Nodes ----
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Visual color (randomized per refugee for visual variety)
var _color: Color = Color.WHITE


func _ready() -> void:
	add_to_group("refugees")
	_color = Color.from_hsv(randf(), 0.7, 0.9)
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


# ---- State Management ----

func _update_state() -> void:
	var best := _find_best_target()
	if best == null:
		# No attractor in range — free roam
		if state != State.WANDERING:
			state = State.WANDERING
			_current_attractor = null
			_pick_new_wander_target()
		return

	if best is SafeHouse:
		# Safe house in range — navigate directly
		state = State.SEEKING
		_current_attractor = best
		navigation_agent.target_position = best.global_position
		return

	# It's an anchor
	if best != _current_attractor:
		# New/better anchor — navigate to it
		state = State.SEEKING
		_current_attractor = best
		navigation_agent.target_position = best.global_position
	elif navigation_agent.is_navigation_finished():
		# Reached current anchor — wander freely within its range
		_wander_near(best)


## Pick a random point within the anchor's range (biased toward safe house)
func _wander_near(anchor: Node2D) -> void:
	state = State.WANDERING
	var radius: float = float(anchor.get("attraction_radius"))
	var sh_pos := _get_safe_house_pos()
	# Direction from safe house TO anchor (we want to stay between anchor and SH)
	var away_from_sh := (anchor.global_position - sh_pos).normalized()
	# Pick random point in the half-circle AWAY from safe house (anchor's back side)
	# This keeps the refugee within the anchor's range without pushing past it
	var angle := randf_range(-PI * 0.6, PI * 0.6)
	var dist := randf_range(radius * 0.2, radius * 0.8)
	_wander_target = anchor.global_position + away_from_sh.rotated(angle) * dist
	navigation_agent.target_position = _wander_target
	_wander_timer = 0.5  # Short wander before re-checking


## Returns the attractor closest to safe house within range
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
		var radius: float = float(source.get("attraction_radius"))
		if dist_to_me > radius:
			continue
		# Skip if already at this anchor (but not SafeHouse)
		if dist_to_me < 8.0 and not (source is SafeHouse):
			continue
		# Pick closest to safe house
		var dist_to_sh := source.global_position.distance_to(sh_pos)
		if dist_to_sh < best_sh_dist:
			best_sh_dist = dist_to_sh
			best = source

	return best


func _get_safe_house_pos() -> Vector2:
	var world := get_tree().get_first_node_in_group("world") as Node2D
	if world and world.has_method("get_safe_house_position"):
		return world.get_safe_house_position()
	return Vector2.ZERO


# ---- Movement ----

func _process_movement() -> void:
	if navigation_agent.is_navigation_finished():
		return
	var next_pos := navigation_agent.get_next_path_position()
	var speed := seek_speed if state == State.SEEKING else wander_speed
	velocity = global_position.direction_to(next_pos) * speed
	move_and_slide()


func _pick_new_wander_target() -> void:
	var angle := randf() * TAU
	var dist := randf() * 120.0 + 40.0
	_wander_target = wander_origin + Vector2.RIGHT.rotated(angle) * dist
	navigation_agent.target_position = _wander_target
	_wander_timer = wander_interval


# ---- Rescue ----

func rescue() -> void:
	if state == State.RESCUED:
		return
	state = State.RESCUED
	GameManager.register_rescue()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(self.queue_free)


func _draw() -> void:
	var radius := 8.0
	draw_circle(Vector2.ZERO, radius, _color)
	if velocity.length() > 10.0:
		var forward := velocity.normalized() * (radius - 2.0)
		draw_circle(forward, 2.5, Color.WHITE)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 16, _color.darkened(0.3), 1.0)
