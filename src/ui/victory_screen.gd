## VictoryScreen — Shown when the player rescues enough refugees before time runs out.
## Displays level stats and provides navigation to next level or retry.
extends Control

# ---- Nodes ----
@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var next_button: Button = %NextButton
@onready var retry_button: Button = %RetryButton
@onready var quit_button: Button = %QuitButton

# ---- References to Main (set via signal or direct path) ----
var _main_ref: Node = null


func _ready() -> void:
	visible = false
	_main_ref = get_tree().get_first_node_in_group("main")
	next_button.pressed.connect(_on_next_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func display_stats(stats: Dictionary) -> void:
	visible = true
	title_label.text = "VICTORY!"
	title_label.modulate = Color.GREEN

	var elapsed: float = stats.get("time_elapsed", 0.0)
	var minutes := int(elapsed) / 60
	var seconds := int(elapsed) % 60
	var rescued: int = stats.get("rescued", 0)
	var target: int = stats.get("target", 0)

	stats_label.text = (
		"Level: %s\n" % stats.get("level_name", "?") +
		"Time: %02d:%02d\n" % [minutes, seconds] +
		"Rescued: %d / %d\n" % [rescued, target] +
		"Success!"
	)


func _on_next_pressed() -> void:
	var main := get_tree().get_first_node_in_group("main") if _main_ref == null else _main_ref
	if main and main.has_method("on_next_level_pressed"):
		main.on_next_level_pressed()


func _on_retry_pressed() -> void:
	var main := get_tree().get_first_node_in_group("main") if _main_ref == null else _main_ref
	if main and main.has_method("on_retry_pressed"):
		main.on_retry_pressed()


func _on_quit_pressed() -> void:
	get_tree().quit()
