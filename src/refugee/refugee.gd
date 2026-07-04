## Refugee — AI-controlled character that wanders until attracted by an anchor/safe house.
## Uses NavigationAgent2D for pathfinding. Implements a 3-state machine.
class_name Refugee
extends CharacterBody2D

# ---- State Machine ----
enum State { WANDERING, SEEKING, RESCUED }

# ---- Exported Properties ----
@export var wander_speed: float = 60.0
@export var seek_speed: float = 100.0
@export var wander_interval: float = 2.0   # Seconds between direction changes
@export var wander_origin: Vector2           # Set by World on spawn

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

	# Random color for visual identification
	_color = Color.from_hsv(randf(), 0.7, 0.9)

	# Configure navigation agent for top-down movement
	navigation_agent.path_desired_distance = 8.0
	navigation_agent.target_desired_distance = 8.0
	navigation_agent.avoidance_enabled = false

	# Defer first path query until nav map is synchronized
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
	if best != null:
		state = State.SEEKING
		_current_attractor = best
		# Navigate THROUGH the attractor toward safe house, not TO its center
		var sh_pos := _get_safe_house_pos()
		var dir_to_sh := best.global_position.direction_to(sh_pos)
		var offset: float = float(best.get("attraction_radius")) * 0.7
		navigation_agent.target_position = best.global_position + dir_to_sh * offset
	else:
		if state != State.WANDERING:
			state = State.WANDERING
			_current_attractor = null
			_pick_new_wander_target()


## Returns the attractor closest to the safe house (within range of this refugee)
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

		# Out of range — skip
		if dist_to_me > radius:
			continue

		# Already at this anchor — skip it (but never skip SafeHouse)
		if dist_to_me < 8.0 and not (source is SafeHouse):
			continue

		# Pick the source closest to the safe house
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
	match state:
		State.WANDERING:
			_process_wandering()
		State.SEEKING:
			_process_seeking()


func _process_wandering() -> void:
	if navigation_agent.is_navigation_finished():
		_wander_timer -= get_physics_process_delta_time()
		if _wander_timer <= 0.0:
			_pick_new_wander_target()
		return

	var next_pos := navigation_agent.get_next_path_position()
	velocity = global_position.direction_to(next_pos) * wander_speed
	move_and_slide()


func _process_seeking() -> void:
	if navigation_agent.is_navigation_finished():
		return

	var next_pos := navigation_agent.get_next_path_position()
	velocity = global_position.direction_to(next_pos) * seek_speed
	move_and_slide()


func _pick_new_wander_target() -> void:
	var angle := randf() * TAU
	var dist := randf() * 120.0 + 40.0  # 40-160 pixels from origin
	_wander_target = wander_origin + Vector2.RIGHT.rotated(angle) * dist
	navigation_agent.target_position = _wander_target
	_wander_timer = wander_interval


# ---- Rescue ----

## Called by SafeHouse when this refugee enters the rescue zone
func rescue() -> void:
	if state == State.RESCUED:
		return
	state = State.RESCUED
	GameManager.register_rescue()
	# Visual feedback: shrink and fade
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(self.queue_free)


func _draw() -> void:
	# Placeholder visual: colored circle with direction indicator
	var radius := 8.0
	draw_circle(Vector2.ZERO, radius, _color)
	if velocity.length() > 10.0:
		var forward := velocity.normalized() * (radius - 2.0)
		draw_circle(forward, 2.5, Color.WHITE)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 16, _color.darkened(0.3), 1.0)
