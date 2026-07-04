## World — 管理游戏世界：导航、地图、安全屋、玩家、难民和锚点。
## 充当各节点之间的中介者。
extends Node2D

# ---- 预加载场景 ----
const REFUGEE_SCENE := preload("res://src/refugee/refugee.tscn")
const TYPE1_ANCHOR := preload("res://src/anchor/anchor_type1.tscn")
const TYPE2_ANCHOR := preload("res://src/anchor/anchor_type2.tscn")
const TYPE3_ANCHOR := preload("res://src/anchor/anchor_type3.tscn")

## 地图随机生成初始锚点数量
@export var type1_count: int = 2
## 地图随机生成大型锚点数量
@export var type2_count: int = 1
## 地图随机生成驱赶锚点数量
@export var type3_count: int = 1

# ---- 节点引用 ----
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var safe_house: SafeHouse = $SafeHouse
@onready var player: Player = $Player
@onready var refugees_container: Node2D = $Refugees
@onready var anchors_container: Node2D = $Anchors

# ---- 状态 ----
var _level_data: LevelData = null


func _ready() -> void:
	add_to_group("world")


func _physics_process(delta: float) -> void:
	if not GameManager.is_level_active:
		return
	GameManager.tick_timer(delta)


# ---- 公开 API ----

## 根据 LevelData 资源设置世界
func setup_level(level_data: LevelData) -> void:
	_level_data = level_data
	_clear_containers()

	safe_house.position = level_data.safe_house_position
	safe_house.attraction_radius = level_data.safe_house_attraction_radius

	# 玩家初始位置在安全屋旁边
	player.global_position = level_data.safe_house_position + Vector2(60, 0)
	player._held_anchor = TYPE1_ANCHOR
	player._held_anchor_radius = 180.0
	if player.anchor_data:
		player.anchor_data.attraction_radius = level_data.anchor_attraction_radius

	_setup_navigation()
	_spawn_random_anchors()
	_spawn_refugees_deferred.call_deferred(level_data)

	GameManager.start_level(level_data)


func _spawn_refugees_deferred(level_data: LevelData) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	for spawn_pos in level_data.refugee_spawn_positions:
		_spawn_refugee(spawn_pos, level_data)


func get_attraction_sources() -> Array[Node2D]:
	var sources: Array[Node2D] = []
	if is_instance_valid(safe_house):
		sources.append(safe_house)
	for anchor in anchors_container.get_children():
		if is_instance_valid(anchor):
			sources.append(anchor as Node2D)
	return sources


func get_safe_house_position() -> Vector2:
	return safe_house.global_position if is_instance_valid(safe_house) else Vector2.ZERO


func get_safe_house_radius() -> float:
	return safe_house.attraction_radius if is_instance_valid(safe_house) else 200.0


func get_safe_house_node() -> Node2D:
	return safe_house if is_instance_valid(safe_house) else null


# ---- 难民生成 ----

func _spawn_refugee(spawn_pos: Vector2, level_data: LevelData) -> void:
	var refugee: Refugee = REFUGEE_SCENE.instantiate()
	refugee.global_position = spawn_pos
	refugee.wander_origin = spawn_pos
	refugee.wander_speed = level_data.refugee_wander_speed
	refugee.seek_speed = level_data.refugee_seek_speed
	refugee.wander_interval = level_data.refugee_wander_interval
	refugees_container.add_child(refugee)


# ---- 导航 ----

func _setup_navigation() -> void:
	var nav_poly := NavigationPolygon.new()
	var outline := PackedVector2Array([
		Vector2(0, 0),
		Vector2(1920, 0),
		Vector2(1920, 1080),
		Vector2(0, 1080),
	])
	nav_poly.add_outline(outline)
	nav_poly.make_polygons_from_outlines()
	navigation_region.navigation_polygon = nav_poly


# ---- 随机锚点 ----

func _spawn_random_anchors() -> void:
	for i in range(type1_count):
		var a := TYPE1_ANCHOR.instantiate()
		a.global_position = Vector2(randf_range(150, 1770), randf_range(150, 930))
		anchors_container.add_child(a)
	for i in range(type2_count):
		var a := TYPE2_ANCHOR.instantiate()
		a.global_position = Vector2(randf_range(150, 1770), randf_range(150, 930))
		anchors_container.add_child(a)
	for i in range(type3_count):
		var a := TYPE3_ANCHOR.instantiate()
		a.global_position = Vector2(randf_range(150, 1770), randf_range(150, 930))
		anchors_container.add_child(a)


# ---- 清理 ----

func _clear_containers() -> void:
	for child in refugees_container.get_children():
		child.queue_free()
	for child in anchors_container.get_children():
		child.queue_free()
