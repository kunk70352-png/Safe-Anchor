## VictoryScreen — 胜利时显示。背景图包含全部视觉内容。
extends Control

@onready var next_button: Button = %NextButton

var _main_ref: Node = null


func _ready() -> void:
	visible = false
	_main_ref = get_tree().get_first_node_in_group("main")
	next_button.pressed.connect(_on_next_pressed)


func display_stats(_stats: Dictionary) -> void:
	visible = true


func _call_main(method: String) -> void:
	var main := get_tree().get_first_node_in_group("main") if _main_ref == null else _main_ref
	if main and main.has_method(method):
		main.call(method)


func _on_next_pressed() -> void:
	AudioManager.play_sfx(load("res://assets/audio/tap.mp3"))
	_call_main("on_next_level_pressed")
