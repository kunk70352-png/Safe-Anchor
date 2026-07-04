## GameManager — 全局单例，追踪当前关卡状态。
## 所有游戏模块通过此管理器的信号通信（观察者模式）。
## 任意脚本通过 GameManager.属性 或 GameManager.方法() 访问。
extends Node

# ============================================================
# 信号
# ============================================================

## 新关卡开始时发出
signal level_started(level_data: LevelData)

## 玩家达到救援目标时发出
signal level_completed(stats: Dictionary)

## 计时器到期但救援不足时发出
signal level_failed(stats: Dictionary)

## 每次难民被救出时发出
signal refugee_rescued(total_rescued: int, target: int)

## 锚点被放置时发出
signal anchor_placed(anchors_used: int, max_anchors: int)

## 剩余时间变化时发出
signal time_updated(time_remaining: float, time_limit: float)

# ============================================================
# 状态（运行时数据，不序列化）
# ============================================================

## 当前关卡的 LevelData 资源
var current_level_data: LevelData = null

## 本关已救出难民数
var rescued_count: int = 0:
	set(value):
		rescued_count = value
		if current_level_data:
			refugee_rescued.emit(rescued_count, current_level_data.target_rescued)

## 倒计时剩余秒数
var time_remaining: float = 0.0

## 玩家已放置锚点数量（上限为 anchor_limit）
var anchors_placed: int = 0

## 关卡是否正在进行中
var is_level_active: bool = false

# ============================================================
# 公开方法
# ============================================================

## 根据给定的 LevelData 资源初始化并开始新关卡
func start_level(level_data: LevelData) -> void:
	current_level_data = level_data
	rescued_count = 0
	time_remaining = level_data.time_limit
	anchors_placed = 0
	is_level_active = true
	level_started.emit(level_data)


## 难民到达安全屋时调用。递增救援计数并检查胜利条件。
func register_rescue() -> void:
	if not is_level_active:
		return
	rescued_count += 1
	if check_win_condition():
		_complete_level()


## 尝试放置锚点。成功返回 true。
func try_place_anchor() -> bool:
	if not is_level_active:
		return false
	if anchors_placed >= current_level_data.anchor_limit:
		return false
	anchors_placed += 1
	anchor_placed.emit(anchors_placed, current_level_data.anchor_limit)
	return true


## 移除锚点（锚点过期时调用）
func remove_anchor() -> void:
	anchors_placed = maxi(anchors_placed - 1, 0)
	anchor_placed.emit(anchors_placed, current_level_data.anchor_limit)


## 检查是否满足胜利条件
func check_win_condition() -> bool:
	if not current_level_data:
		return false
	return rescued_count >= current_level_data.target_rescued


## 检查是否满足失败条件
func check_lose_condition() -> bool:
	return time_remaining <= 0.0 and not check_win_condition()


## World 每物理帧调用此方法推进倒计时
func tick_timer(delta: float) -> void:
	if not is_level_active:
		return
	time_remaining = maxf(time_remaining - delta, 0.0)
	time_updated.emit(time_remaining, current_level_data.time_limit)
	if check_lose_condition():
		_fail_level()


## 重置所有状态，准备新关卡
func reset_for_new_level() -> void:
	current_level_data = null
	rescued_count = 0
	time_remaining = 0.0
	anchors_placed = 0
	is_level_active = false


# ============================================================
# 私有方法
# ============================================================

func _complete_level() -> void:
	is_level_active = false
	var elapsed := current_level_data.time_limit - time_remaining
	var stats := {
		"level": current_level_data.level_number,
		"level_name": current_level_data.level_name,
		"time_elapsed": snapped(elapsed, 0.1),
		"time_limit": current_level_data.time_limit,
		"rescued": rescued_count,
		"target": current_level_data.target_rescued,
	}
	level_completed.emit(stats)


func _fail_level() -> void:
	is_level_active = false
	var stats := {
		"level": current_level_data.level_number,
		"level_name": current_level_data.level_name,
		"time_elapsed": current_level_data.time_limit,
		"time_limit": current_level_data.time_limit,
		"rescued": rescued_count,
		"target": current_level_data.target_rescued,
	}
	level_failed.emit(stats)
