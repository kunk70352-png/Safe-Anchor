## 关卡选择界面 — 列出所有关卡供玩家选择。
extends Control

signal level_selected(level_index: int)
signal back_pressed()

var _levels: Array[LevelData] = []


func _ready() -> void:
	_load_levels()
	_create_buttons()
	$Panel/BackButton.pressed.connect(_on_back)


func _load_levels() -> void:
	for i in range(1, 10):
		var path := "res://resources/levels/level_%d.tres" % i
		if ResourceLoader.exists(path):
			var ld := load(path) as LevelData
			if ld:
				_levels.append(ld)


func _create_buttons() -> void:
	var list := $Panel/VBoxContainer
	for i in _levels.size():
		var ld := _levels[i]
		var btn := Button.new()
		btn.text = "第%d关  %s\n目标: %d人" % [ld.level_number, ld.level_name, ld.target_rescued]
		btn.custom_minimum_size = Vector2(300, 55)
		btn.pressed.connect(_on_level_pressed.bind(i))
		list.add_child(btn)


func _on_level_pressed(index: int) -> void:
	AudioManager.play_sfx(load("res://assets/audio/tap.mp3"))
	level_selected.emit(index)


func _on_back() -> void:
	AudioManager.play_sfx(load("res://assets/audio/tap.mp3"))
	back_pressed.emit()
