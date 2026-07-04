## HUD — In-game heads-up display showing level info, rescue progress, timer, and anchor count.
extends Control

# ---- Nodes ----
@onready var level_label: Label = %LevelLabel
@onready var rescued_label: Label = %RescuedLabel
@onready var timer_label: Label = %TimerLabel
@onready var anchors_label: Label = %AnchorsLabel


func _ready() -> void:
	GameManager.level_started.connect(_on_level_started)
	GameManager.refugee_rescued.connect(_on_refugee_rescued)
	GameManager.anchor_placed.connect(_on_anchor_placed)
	GameManager.time_updated.connect(_on_time_updated)


func _process(_delta: float) -> void:
	if not GameManager.is_level_active:
		return
	_update_timer_display()


# ---- Signal Handlers ----

func _on_level_started(level_data: LevelData) -> void:
	level_label.text = "Level %d: %s" % [level_data.level_number, level_data.level_name]
	rescued_label.text = "Rescued: 0 / %d" % level_data.target_rescued
	anchors_label.text = "Anchors: 0 / %d" % level_data.anchor_limit
	timer_label.modulate = Color.WHITE


func _on_refugee_rescued(total: int, target: int) -> void:
	rescued_label.text = "Rescued: %d / %d" % [total, target]


func _on_anchor_placed(used: int, max_count: int) -> void:
	anchors_label.text = "Anchors: %d / %d" % [used, max_count]
	if used >= max_count:
		anchors_label.modulate = Color.RED


func _on_time_updated(remaining: float, limit: float) -> void:
	pass  # Handled in _process for smooth display


# ---- Display ----

func _update_timer_display() -> void:
	var remaining := GameManager.time_remaining
	var minutes := int(remaining) / 60
	var seconds := int(remaining) % 60
	timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

	# Urgency: turn red when under 10 seconds
	if remaining <= 10.0:
		timer_label.modulate = Color.RED
	elif remaining <= 20.0:
		timer_label.modulate = Color.ORANGE
