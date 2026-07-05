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

## 关卡是否正在进行中
var is_level_active: bool = false

# ============================================================
# 公开方法
# ============================================================

## 根据给定的 LevelData 资源初始化并开始新关卡
func start_level(level_data: LevelData) -> void:
	current_level_data = level_data
	rescued_count = 0
	is_level_active = true
	level_started.emit(level_data)


## 难民到达安全屋时调用。递增救援计数并检查胜利条件。
func register_rescue() -> void:
	if not is_level_active:
		return
	rescued_count += 1
	if check_win_condition():
		_complete_level()


## 检查是否满足胜利条件
func check_win_condition() -> bool:
	if not current_level_data:
		return false
	return rescued_count >= current_level_data.target_rescued


## 重置所有状态，准备新关卡
func reset_for_new_level() -> void:
	current_level_data = null
	rescued_count = 0
	is_level_active = false


## 关卡失败时调用，停止运算并发出信号。
func fail_level(stats: Dictionary) -> void:
	if not is_level_active:
		return
	is_level_active = false
	level_failed.emit(stats)


# ============================================================
# 私有方法
# ============================================================

func _complete_level() -> void:
	is_level_active = false
	var stats := {
		"level": current_level_data.level_number,
		"level_name": current_level_data.level_name,
		"rescued": rescued_count,
		"target": current_level_data.target_rescued,
	}
	level_completed.emit(stats)
