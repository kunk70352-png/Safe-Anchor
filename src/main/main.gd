## Main — Root entry point for the game.
## Follows the Main > World + GUI pattern (Godot best practice, gdd_0045).
## Loads levels, orchestrates the World and GUI, and handles game flow.
extends Node

# ---- Preloaded Scenes ----
const WORLD_SCENE := preload("res://src/world/world.tscn")
const HUD_SCENE := preload("res://src/ui/hud.tscn")
const VICTORY_SCENE := preload("res://src/ui/victory_screen.tscn")
const DEFEAT_SCENE := preload("res://src/ui/defeat_screen.tscn")

# ---- Level Resources ----
var _levels: Array[LevelData] = []
var _current_level_index: int = 0

# ---- Nodes ----
@onready var world: Node2D = $World
@onready var gui: CanvasLayer = $GUI
@onready var hud: Control = $GUI/HUD
@onready var victory_screen: Control = $GUI/VictoryScreen
@onready var defeat_screen: Control = $GUI/DefeatScreen


func _ready() -> void:
	_load_levels()
	_connect_signals()
	_show_hud_only()
	_start_current_level()


func _load_levels() -> void:
	_levels.clear()
	# Load level resources in order
	for i in range(1, 4):  # levels 1-3
		var path := "res://resources/levels/level_%d.tres" % i
		if ResourceLoader.exists(path):
			var level_data := load(path) as LevelData
			if level_data:
				_levels.append(level_data)


func _connect_signals() -> void:
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.level_failed.connect(_on_level_failed)


func _start_current_level() -> void:
	if _current_level_index >= _levels.size():
		_on_all_levels_complete()
		return

	_show_hud_only()
	var level_data := _levels[_current_level_index]
	world.setup_level(level_data)


# ---- UI Management ----

func _show_hud_only() -> void:
	hud.visible = true
	victory_screen.visible = false
	defeat_screen.visible = false


func _show_victory(stats: Dictionary) -> void:
	hud.visible = false
	victory_screen.visible = true
	victory_screen.display_stats(stats)


func _show_defeat(stats: Dictionary) -> void:
	hud.visible = false
	defeat_screen.visible = true
	defeat_screen.display_stats(stats)


# ---- Game Event Handlers ----

func _on_level_completed(stats: Dictionary) -> void:
	_show_victory(stats)


func _on_level_failed(stats: Dictionary) -> void:
	_show_defeat(stats)


func _on_all_levels_complete() -> void:
	# TODO: Show a "Congratulations! All levels complete!" screen
	# For now, cycle back to level 1
	_current_level_index = 0
	_start_current_level()


# ---- Button Callbacks (connected via signals in scene) ----

func on_next_level_pressed() -> void:
	_current_level_index += 1
	_start_current_level()


func on_retry_pressed() -> void:
	GameManager.reset_for_new_level()
	_start_current_level()


func on_quit_pressed() -> void:
	get_tree().quit()
