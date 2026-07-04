## DefeatScreen — Shown when time runs out without enough rescues.
## Displays level stats and provides retry option.
extends Control

# ---- Nodes ----
@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var retry_button: Button = %RetryButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func display_stats(stats: Dictionary) -> void:
	visible = true
	title_label.text = "TIME'S UP!"
	title_label.modulate = Color.RED

	var elapsed: float = stats.get("time_elapsed", 0.0)
	var minutes := int(elapsed) / 60
	var seconds := int(elapsed) % 60
	var rescued: int = stats.get("rescued", 0)
	var target: int = stats.get("target", 0)
	var missing := target - rescued

	stats_label.text = (
		"Level: %s\n" % stats.get("level_name", "?") +
		"Time: %02d:%02d\n" % [minutes, seconds] +
		"Rescued: %d / %d\n" % [rescued, target] +
		"Only %d more needed!" % missing
	)


func _on_retry_pressed() -> void:
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("on_retry_pressed"):
		main.on_retry_pressed()


func _on_quit_pressed() -> void:
	get_tree().quit()
