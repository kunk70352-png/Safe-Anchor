## GameManager — Global Autoload singleton that tracks the state of the current level.
## All game modules communicate through this manager's signals (Observer pattern).
## Access from any script via: GameManager.property or GameManager.method()
extends Node

# ============================================================
# Signals (past-tense naming convention per Godot style guide)
# ============================================================

## Emitted when a new level starts
signal level_started(level_data: LevelData)

## Emitted when the player meets the rescue target
signal level_completed(stats: Dictionary)

## Emitted when the timer expires without enough rescues
signal level_failed(stats: Dictionary)

## Emitted each time a refugee is rescued
signal refugee_rescued(total_rescued: int, target: int)

## Emitted when an anchor is placed
signal anchor_placed(anchors_used: int, max_anchors: int)

## Emitted when remaining time changes (every second)
signal time_updated(time_remaining: float, time_limit: float)

# ============================================================
# State (transient, not serialized)
# ============================================================

## The LevelData resource for the currently active level
var current_level_data: LevelData = null

## How many refugees have been rescued so far this level
var rescued_count: int = 0:
	set(value):
		rescued_count = value
		if current_level_data:
			refugee_rescued.emit(rescued_count, current_level_data.target_rescued)

## How many seconds remain in the countdown
var time_remaining: float = 0.0

## How many anchors the player has placed (capped at anchor_limit)
var anchors_placed: int = 0

## Whether a level is currently in progress
var is_level_active: bool = false

# ============================================================
# Public Methods
# ============================================================

## Initialize and start a new level from the given LevelData resource
func start_level(level_data: LevelData) -> void:
	current_level_data = level_data
	rescued_count = 0
	time_remaining = level_data.time_limit
	anchors_placed = 0
	is_level_active = true
	level_started.emit(level_data)


## Call this when a refugee reaches the safe house.
## Increments the rescue count and checks for win condition.
func register_rescue() -> void:
	if not is_level_active:
		return
	rescued_count += 1
	if check_win_condition():
		_complete_level()


## Attempt to place an anchor. Returns true if successful.
func try_place_anchor() -> bool:
	if not is_level_active:
		return false
	if anchors_placed >= current_level_data.anchor_limit:
		return false
	anchors_placed += 1
	anchor_placed.emit(anchors_placed, current_level_data.anchor_limit)
	return true


## Remove an anchor (when its lifetime expires)
func remove_anchor() -> void:
	anchors_placed = maxi(anchors_placed - 1, 0)
	anchor_placed.emit(anchors_placed, current_level_data.anchor_limit)


## Check if the win condition is met
func check_win_condition() -> bool:
	if not current_level_data:
		return false
	return rescued_count >= current_level_data.target_rescued


## Check if the lose condition is met
func check_lose_condition() -> bool:
	return time_remaining <= 0.0 and not check_win_condition()


## Called by World every physics frame to tick the countdown
func tick_timer(delta: float) -> void:
	if not is_level_active:
		return
	time_remaining = maxf(time_remaining - delta, 0.0)
	time_updated.emit(time_remaining, current_level_data.time_limit)
	if check_lose_condition():
		_fail_level()


## Reset everything for a new level
func reset_for_new_level() -> void:
	current_level_data = null
	rescued_count = 0
	time_remaining = 0.0
	anchors_placed = 0
	is_level_active = false


# ============================================================
# Private Methods
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
