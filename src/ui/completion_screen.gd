## 通关界面 — 全部关卡完成后显示。
extends Control


func _ready() -> void:
	visible = false
	$Panel/VBoxContainer/BackButton.pressed.connect(_on_back)


func show_screen() -> void:
	visible = true


func _on_back() -> void:
	AudioManager.play_sfx(load("res://assets/audio/tap.mp3"))
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("on_return_to_title"):
		main.on_return_to_title()