## Main — 游戏根入口。标题→选关→游戏。
extends Node

var _levels: Array[LevelData] = []
var _current_level_index: int = 0

@onready var world = $World
@onready var gui: CanvasLayer = $GUI
@onready var title_screen: Control = $GUI/TitleScreen
@onready var level_select: Control = $GUI/LevelSelect
@onready var hud: Control = $GUI/HUD
@onready var victory_screen: Control = $GUI/VictoryScreen
@onready var defeat_screen: Control = $GUI/DefeatScreen
@onready var completion_screen: Control = $GUI/CompletionScreen


func _ready() -> void:
	_load_levels()
	_connect_signals()
	_show_title()


func _show_title() -> void:
	title_screen.visible = true
	level_select.visible = false
	hud.visible = false
	victory_screen.visible = false
	defeat_screen.visible = false
	completion_screen.visible = false


func on_start_game() -> void:
	_show_level_select()


func _load_levels() -> void:
	_levels.clear()
	for i in range(1, 10):
		var path := "res://resources/levels/level_%d.tres" % i
		if ResourceLoader.exists(path):
			var level_data := load(path) as LevelData
			if level_data:
				_levels.append(level_data)


func _connect_signals() -> void:
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.level_failed.connect(_on_level_failed)
	level_select.level_selected.connect(_on_level_selected)
	level_select.back_pressed.connect(_show_title)


func _show_level_select() -> void:
	title_screen.visible = false
	level_select.visible = true
	hud.visible = false
	victory_screen.visible = false
	defeat_screen.visible = false


func _on_level_selected(index: int) -> void:
	_current_level_index = index
	_start_current_level()


func _start_current_level() -> void:
	if _current_level_index >= _levels.size():
		return
	title_screen.visible = false
	level_select.visible = false
	hud.visible = true
	victory_screen.visible = false
	defeat_screen.visible = false
	var level_data := _levels[_current_level_index]
	world.setup_level(level_data)


func _show_victory(stats: Dictionary) -> void:
	hud.visible = false
	victory_screen.visible = true
	victory_screen.display_stats(stats)


func _show_defeat(stats: Dictionary) -> void:
	hud.visible = false
	defeat_screen.visible = true
	defeat_screen.display_stats(stats)


func _on_level_completed(stats: Dictionary) -> void:
	_show_victory(stats)


func _on_level_failed(stats: Dictionary) -> void:
	_show_defeat(stats)


func on_next_level_pressed() -> void:
	_current_level_index += 1
	if _current_level_index >= _levels.size():
		_show_completion()
		return
	_start_current_level()


func on_retry_pressed() -> void:
	GameManager.reset_for_new_level()
	_start_current_level()


func on_quit_pressed() -> void:
	_show_level_select()


func on_return_to_select() -> void:
	GameManager.reset_for_new_level()
	_show_level_select()


func on_return_to_title() -> void:
	GameManager.reset_for_new_level()
	_show_title()


func _show_completion() -> void:
	completion_screen.visible = true
	completion_screen.show_screen()
	hud.visible = false
	title_screen.visible = false
	level_select.visible = false
	victory_screen.visible = false
	defeat_screen.visible = false
