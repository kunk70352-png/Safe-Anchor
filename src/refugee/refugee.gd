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


func _ready() -> void:
	add_to_group("refugees")

	# Configure navigation agent for top-down movement
	navigation_agent.path_desired_distance = 8.0
	navigation_agent.target_desired_distance = 8.0
	navigation_agent.avoidance_enabled = false

	# Defer first path query until nav map is synchronized
	_setup_navigation.call_deferred()

	# Bobbing animation for idle/movement
	if animation_player and animation_player.has_animation("bob"):
		animation_player.play("bob")


func _setup_navigation() -> void:
	# Wait one physics frame for navigation map to sync
	await get_tree().physics_frame
	_pick_new_wander_target()


func _physics_process(delta: float) -> void:
	if state == State.RESCUED:
		return

	_update_state()
	_process_movement()


# ---- State Management ----

func _update_state() -> void:
	# Find nearest attraction source within range
	var nearest := _find_nearest_attractor()
	if nearest != null:
		state = State.SEEKING
		_current_attractor = nearest
		navigation_agent.target_position = nearest.global_position
	else:
		state = State.WANDERING
		_current_attractor = null


func _find_nearest_attractor() -> Node2D:
	var world := get_tree().get_first_node_in_group("world") as Node2D
	if world == null or not world.has_method("get_attraction_sources"):
		return null

	var sources: Array[Node2D] = world.get_attraction_sources()
	if sources.is_empty():
		return null

	var nearest: Node2D = null
	var nearest_dist: float = INF

	for source in sources:
		if not is_instance_valid(source):
			continue
		var dist := global_position.distance_to(source.global_position)
		# Get the attraction radius from the source
		var radius: float = 0.0
		if source.has_method("get_attraction_radius"):
			radius = source.get_attraction_radius()
		elif source.get("attraction_radius") != null:
			radius = source.attraction_radius
		else:
			continue

		if dist <= radius and dist < nearest_dist:
			nearest = source
			nearest_dist = dist

	return nearest


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
		# Reached the attractor — check if it's the safe house
		if _current_attractor and _current_attractor is SafeHouse:
			# Close enough to rescue? The SafeHouse rescue Area2D handles this.
			# But also check directly as a fallback
			pass
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
	tween.tween_callback(queue_free)
