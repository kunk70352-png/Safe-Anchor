## Main — 游戏根入口。
## 遵循 Main > World + GUI 架构模式（Godot 最佳实践）。
## 加载关卡、编排 World 和 GUI、处理游戏流程。
extends Node

# ---- 关卡资源 ----
var _levels: Array[LevelData] = []
var _current_level_index: int = 0

# ---- 节点引用 ----
@onready var world = $World
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
	# 按顺序加载关卡资源
	for i in range(1, 4):  # 关卡 1-3
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


# ---- UI 管理 ----

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


# ---- 游戏事件处理 ----

func _on_level_completed(stats: Dictionary) -> void:
	_show_victory(stats)


func _on_level_failed(stats: Dictionary) -> void:
	_show_defeat(stats)


func _on_all_levels_complete() -> void:
	# 全部关卡完成 — 暂时退出（避免无限递归）
	printerr("所有关卡已完成，没有更多可加载的关卡。")
	get_tree().quit()


# ---- 按钮回调（在场景中通过信号连接） ----

func on_next_level_pressed() -> void:
	_current_level_index += 1
	_start_current_level()


func on_retry_pressed() -> void:
	GameManager.reset_for_new_level()
	_start_current_level()


func on_quit_pressed() -> void:
	get_tree().quit()
