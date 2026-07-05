## DefeatScreen — 时间耗尽且救援不足时显示。背景图包含全部视觉内容。
extends Control

@onready var retry_button: Button = %RetryButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func display_stats(_stats: Dictionary) -> void:
	var defeat_list := [
		"res://assets/audio/bgm_defeat1.mp3",
		"res://assets/audio/bgm_defeat2.mp3",
		"res://assets/audio/bgm_defeat3.mp3",
	]
	AudioManager.play_bgm(load(defeat_list[randi() % defeat_list.size()]))
	visible = true


func _on_retry_pressed() -> void:
	AudioManager.play_sfx(load("res://assets/audio/tap.mp3"))
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("on_retry_pressed"):
		main.on_retry_pressed()


func _on_quit_pressed() -> void:
	AudioManager.play_sfx(load("res://assets/audio/tap.mp3"))
	get_tree().quit()
