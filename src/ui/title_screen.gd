## 标题界面 — 开始游戏、退出、世界观介绍。
extends Control


func _ready() -> void:
	%StartButton.pressed.connect(_on_start)
	%QuitButton.pressed.connect(_on_quit)


func _on_start() -> void:
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("on_start_game"):
		main.on_start_game()


func _on_quit() -> void:
	get_tree().quit()
