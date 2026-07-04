## 关卡选择界面 — 游戏启动时显示，列出所有关卡供玩家选择。
extends Control

signal level_selected(level_index: int)

var _levels: Array[LevelData] = []
var _buttons: Array[Button] = []


func _ready() -> void:
	_load_levels()
	_create_buttons()


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
		btn.text = "第%d关: %s\n目标: %d人 | 时间: %ds" % [ld.level_number, ld.level_name, ld.target_rescued, int(ld.time_limit)]
		btn.custom_minimum_size = Vector2(300, 60)
		btn.pressed.connect(_on_level_pressed.bind(i))
		list.add_child(btn)
		_buttons.append(btn)


func _on_level_pressed(index: int) -> void:
	level_selected.emit(index)
