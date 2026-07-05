## VictoryScreen — 胜利时显示。展示统计并提供下一关/重试/返回。
extends Control

@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var next_button: Button = %NextButton
@onready var retry_button: Button = %RetryButton
@onready var back_button: Button = %BackButton

var _main_ref: Node = null


func _ready() -> void:
	visible = false
	_main_ref = get_tree().get_first_node_in_group("main")
	next_button.pressed.connect(_on_next_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	back_button.pressed.connect(_on_back_pressed)


func display_stats(stats: Dictionary) -> void:
	AudioManager.play_bgm(load("res://assets/audio/bgm_victory.mp3"))
	visible = true
	title_label.text = "胜利！"
	title_label.modulate = Color.GREEN

	var rescued: int = stats.get("rescued", 0)
	var target: int = stats.get("target", 0)

	stats_label.text = (
		"关卡: %s\n" % stats.get("level_name", "?") +
		"救出: %d / %d" % [rescued, target]
	)


func _call_main(method: String) -> void:
	var main := get_tree().get_first_node_in_group("main") if _main_ref == null else _main_ref
	if main and main.has_method(method):
		main.call(method)


func _on_next_pressed() -> void:
	_call_main("on_next_level_pressed")


func _on_retry_pressed() -> void:
	_call_main("on_retry_pressed")


func _on_back_pressed() -> void:
	_call_main("on_return_to_select")
