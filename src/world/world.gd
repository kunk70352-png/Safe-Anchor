## World — 管理游戏世界：导航、地图、安全屋、难民和锚点。
## 充当 SafeHouse、Anchor、Refugee 节点之间的中介者。
## 处理玩家放置锚点的输入。
extends Node2D

# ---- 预加载场景 ----
const REFUGEE_SCENE := preload("res://src/refugee/refugee.tscn")
const ANCHOR_SCENE := preload("res://src/anchor/anchor.tscn")

# ---- 节点引用 ----
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var safe_house: SafeHouse = $SafeHouse
@onready var refugees_container: Node2D = $Refugees
@onready var anchors_container: Node2D = $Anchors
@onready var level_timer: Timer = $LevelTimer

# ---- 状态 ----
var _level_data: LevelData = null
var _time_elapsed: float = 0.0


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

	# 清除上一关的残留
	_clear_containers()

	# 定位并配置安全屋
	safe_house.position = level_data.safe_house_position
	safe_house.attraction_radius = level_data.safe_house_attraction_radius

	# 设置导航多边形（覆盖整个游戏区域）
	_setup_navigation()

	# 延迟生成难民（等导航网格烘焙完成）
	_spawn_refugees_deferred.call_deferred(level_data)

	# 通知 GameManager
	GameManager.start_level(level_data)


func _spawn_refugees_deferred(level_data: LevelData) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	for spawn_pos in level_data.refugee_spawn_positions:
		_spawn_refugee(spawn_pos, level_data)


## 返回所有活跃的吸引源（安全屋 + 所有已放置的锚点）
func get_attraction_sources() -> Array[Node2D]:
	var sources: Array[Node2D] = []
	if is_instance_valid(safe_house):
		sources.append(safe_house)
	for anchor in anchors_container.get_children():
		if is_instance_valid(anchor):
			sources.append(anchor as Node2D)
	return sources


## 返回安全屋全局坐标，供距离计算使用
func get_safe_house_position() -> Vector2:
	return safe_house.global_position if is_instance_valid(safe_house) else Vector2.ZERO


# ---- 输入处理 ----

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_level_active:
		return
	if event.is_action_pressed("place_anchor"):
		var click_pos := get_global_mouse_position()
		_try_place_anchor(click_pos)


# ---- 锚点放置 ----

func _try_place_anchor(pos: Vector2) -> void:
	if not _can_place_anchor(pos):
		return

	if not GameManager.try_place_anchor():
		return  # 锚点数量已用完

	var anchor: Anchor = ANCHOR_SCENE.instantiate()
	anchor.global_position = pos
	anchor.attraction_radius = _level_data.anchor_attraction_radius
	anchor.lifetime = 15.0  # 后续可在 LevelData 中配置
	anchor.lifetime_expired.connect(_on_anchor_expired)
	anchors_container.add_child(anchor)


func _can_place_anchor(pos: Vector2) -> bool:
	# TODO: 验证位置是否在导航网格内
	# 目前仅确保不紧贴安全屋
	if safe_house.global_position.distance_to(pos) < safe_house.rescue_radius + 20.0:
		return false
	return true


func _on_anchor_expired(_anchor: Anchor) -> void:
	pass  # 锚点自行 queue_free，GameManager.remove_anchor() 在 anchor.gd 中调用


# ---- 难民生成 ----

func _spawn_refugee(spawn_pos: Vector2, level_data: LevelData) -> void:
	var refugee: Refugee = REFUGEE_SCENE.instantiate()
	refugee.global_position = spawn_pos
	refugee.wander_origin = spawn_pos
	refugee.wander_speed = level_data.refugee_wander_speed
	refugee.seek_speed = level_data.refugee_seek_speed
	refugee.wander_interval = level_data.refugee_wander_interval
	refugees_container.add_child(refugee)


# ---- 导航设置 ----

func _setup_navigation() -> void:
	var nav_poly := NavigationPolygon.new()
	# 覆盖 1280x720 完整游戏区域
	var outline := PackedVector2Array([
		Vector2(0, 0),
		Vector2(1280, 0),
		Vector2(1280, 720),
		Vector2(0, 720),
	])
	nav_poly.add_outline(outline)
	nav_poly.make_polygons_from_outlines()
	navigation_region.navigation_polygon = nav_poly


# ---- 清理 ----

func _clear_containers() -> void:
	for child in refugees_container.get_children():
		child.queue_free()
	for child in anchors_container.get_children():
		child.queue_free()
