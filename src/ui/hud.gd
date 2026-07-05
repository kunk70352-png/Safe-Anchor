## HUD — 显示关卡信息、救援进度、锚点状态。
extends Control

@onready var level_label: Label = %LevelLabel
@onready var rescued_label: Label = %RescuedLabel
@onready var anchors_label: Label = %AnchorsLabel
@onready var give_up_button: Button = %GiveUpButton


func _ready() -> void:
	GameManager.level_started.connect(_on_level_started)
	GameManager.refugee_rescued.connect(_on_refugee_rescued)
	give_up_button.pressed.connect(_on_give_up)


func _process(_delta: float) -> void:
	if not GameManager.is_level_active:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		var carrying := player._held_anchor != null
		anchors_label.text = "锚点: %s" % ("持有" if carrying else "无")
		anchors_label.modulate = Color.GREEN if carrying else Color.ORANGE


func _on_level_started(level_data: LevelData) -> void:
	level_label.text = "第%d关  %s" % [level_data.level_number, level_data.level_name]
	rescued_label.text = "已救出: 0 / %d" % level_data.target_rescued


func _on_refugee_rescued(total: int, target: int) -> void:
	rescued_label.text = "已救出: %d / %d" % [total, target]


func _on_give_up() -> void:
	AudioManager.play_sfx(load("res://assets/audio/tap.mp3"))
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("on_return_to_select"):
		main.on_return_to_select()
