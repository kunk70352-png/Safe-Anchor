## Refugee — AI 控制角色，被锚点/安全屋吸引前随机徘徊。
## 使用 NavigationAgent2D 寻路，实现三状态状态机。
class_name Refugee
extends CharacterBody2D

# ---- 状态机 ----
enum State { WANDERING, SEEKING, RESCUED }

# ---- 导出属性 ----
@export var wander_speed: float = 60.0
@export var seek_speed: float = 100.0
@export var wander_interval: float = 2.0
@export var wander_origin: Vector2

# ---- 内部状态 ----
var state: State = State.WANDERING
var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _current_attractor: Node2D = null

# ---- 节点引用 ----
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 视觉颜色（每个难民随机生成，便于区分）
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


# ---- 状态管理 ----

func _update_state() -> void:
	var best := _find_best_target()
	if best == null:
		# 范围内无吸引源 — 自由徘徊
		if state != State.WANDERING:
			state = State.WANDERING
			_current_attractor = null
			_pick_new_wander_target()
		return

	if best is SafeHouse:
		# 安全屋在范围内 — 直接导航
		state = State.SEEKING
		_current_attractor = best
		navigation_agent.target_position = best.global_position
		return

	# 是锚点
	if best != _current_attractor:
		# 新的/更好的锚点 — 导航过去
		state = State.SEEKING
		_current_attractor = best
		navigation_agent.target_position = best.global_position
	elif navigation_agent.is_navigation_finished():
		# 已到达当前锚点，无更好的 — 在范围内自由走动
		_wander_near(best)


## 在锚点范围内选一个随机点（偏向安全屋反方向，确保持续在范围内）
func _wander_near(anchor: Node2D) -> void:
	state = State.WANDERING
	var radius: float = float(anchor.get("attraction_radius"))
	var sh_pos := _get_safe_house_pos()
	# 从安全屋指向锚点的方向（我们希望留在锚点后方，不越过锚点）
	var away_from_sh := (anchor.global_position - sh_pos).normalized()
	# 在锚点后方半圆内随机选点
	var angle := randf_range(-PI * 0.6, PI * 0.6)
	var dist := randf_range(radius * 0.2, radius * 0.8)
	_wander_target = anchor.global_position + away_from_sh.rotated(angle) * dist
	navigation_agent.target_position = _wander_target
	_wander_timer = 0.5  # 短暂徘徊后重新检查


## 返回范围内离安全屋最近的吸引源
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
		# 已在锚点位置则跳过（但不跳过安全屋）
		if dist_to_me < 8.0 and not (source is SafeHouse):
			continue
		# 选离安全屋最近的（引导难民前进）
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


# ---- 移动 ----

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


# ---- 救援 ----

## 由 SafeHouse 在难民进入救援区域时调用
func rescue() -> void:
	if state == State.RESCUED:
		return
	state = State.RESCUED
	GameManager.register_rescue()
	# 视觉反馈：缩小消失
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
