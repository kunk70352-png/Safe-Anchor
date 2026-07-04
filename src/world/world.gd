## World — Manages the game world: navigation, tile map, safe house, refugees, and anchors.
## Acts as the mediator between SafeHouse, Anchor, and Refugee nodes.
## Handles player input for anchor placement.
extends Node2D

# ---- Signals ----
# (Timer updates flow through GameManager.time_updated)

# ---- Preloaded Scenes ----
const REFUGEE_SCENE := preload("res://src/refugee/refugee.tscn")
const ANCHOR_SCENE := preload("res://src/anchor/anchor.tscn")

# ---- Nodes ----
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var safe_house: SafeHouse = $SafeHouse
@onready var refugees_container: Node2D = $Refugees
@onready var anchors_container: Node2D = $Anchors
@onready var level_timer: Timer = $LevelTimer

# ---- State ----
var _level_data: LevelData = null
var _time_elapsed: float = 0.0


func _ready() -> void:
	add_to_group("world")


func _physics_process(delta: float) -> void:
	if not GameManager.is_level_active:
		return
	GameManager.tick_timer(delta)


# ---- Public API ----

## Set up the world from a LevelData resource
func setup_level(level_data: LevelData) -> void:
	_level_data = level_data

	# Clear previous state
	_clear_containers()

	# Position and configure safe house
	safe_house.position = level_data.safe_house_position
	safe_house.attraction_radius = level_data.safe_house_attraction_radius

	# Set up navigation polygon (full play area)
	_setup_navigation()

	# Spawn refugees
	for spawn_pos in level_data.refugee_spawn_positions:
		_spawn_refugee(spawn_pos, level_data)

	# Update GameManager
	GameManager.start_level(level_data)


## Returns all active attraction sources (SafeHouse + all placed Anchors)
func get_attraction_sources() -> Array[Node2D]:
	var sources: Array[Node2D] = []
	if is_instance_valid(safe_house):
		sources.append(safe_house)
	for anchor in anchors_container.get_children():
		if is_instance_valid(anchor):
			sources.append(anchor as Node2D)
	return sources


# ---- Input Handling ----

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_level_active:
		return
	if event.is_action_pressed("place_anchor"):
		var click_pos := get_global_mouse_position()
		_try_place_anchor(click_pos)


# ---- Anchor Placement ----

func _try_place_anchor(pos: Vector2) -> void:
	if not _can_place_anchor(pos):
		return

	if not GameManager.try_place_anchor():
		return  # Out of anchors

	var anchor: Anchor = ANCHOR_SCENE.instantiate()
	anchor.global_position = pos
	anchor.attraction_radius = _level_data.anchor_attraction_radius
	anchor.lifetime = 15.0  # Can be made configurable in LevelData later
	anchor.lifetime_expired.connect(_on_anchor_expired)
	anchors_container.add_child(anchor)


func _can_place_anchor(pos: Vector2) -> bool:
	# TODO: Validate position is within navigation mesh
	# For now, just ensure it's not too close to the safe house
	if safe_house.global_position.distance_to(pos) < safe_house.rescue_radius + 20.0:
		return false
	return true


func _on_anchor_expired(_anchor: Anchor) -> void:
	pass  # Anchor handles its own queue_free; GameManager.remove_anchor() called in anchor.gd


# ---- Refugee Spawning ----

func _spawn_refugee(spawn_pos: Vector2, level_data: LevelData) -> void:
	var refugee: Refugee = REFUGEE_SCENE.instantiate()
	refugee.global_position = spawn_pos
	refugee.wander_origin = spawn_pos
	refugee.wander_speed = level_data.refugee_wander_speed
	refugee.seek_speed = level_data.refugee_seek_speed
	refugee.wander_interval = level_data.refugee_wander_interval
	refugees_container.add_child(refugee)


# ---- Navigation Setup ----

func _setup_navigation() -> void:
	var nav_poly := NavigationPolygon.new()
	# Cover the full 1280x720 play area with a simple rectangle
	var outline := PackedVector2Array([
		Vector2(0, 0),
		Vector2(1280, 0),
		Vector2(1280, 720),
		Vector2(0, 720),
	])
	nav_poly.add_outline(outline)
	nav_poly.make_polygons_from_outlines()
	navigation_region.navigation_polygon = nav_poly


# ---- Cleanup ----

func _clear_containers() -> void:
	for child in refugees_container.get_children():
		child.queue_free()
	for child in anchors_container.get_children():
		child.queue_free()
