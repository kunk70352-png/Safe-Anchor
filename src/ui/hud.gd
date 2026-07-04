## HUD — 游戏内抬头显示，展示关卡信息、救援进度、倒计时和锚点状态。
extends Control

# ---- 节点引用 ----
@onready var level_label: Label = %LevelLabel
@onready var rescued_label: Label = %RescuedLabel
@onready var timer_label: Label = %TimerLabel
@onready var anchors_label: Label = %AnchorsLabel
@onready var give_up_button: Button = %GiveUpButton


func _ready() -> void:
	GameManager.level_started.connect(_on_level_started)
	GameManager.refugee_rescued.connect(_on_refugee_rescued)
	GameManager.time_updated.connect(_on_time_updated)
	give_up_button.pressed.connect(_on_give_up)


func _on_give_up() -> void:
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("on_return_to_select"):
		main.on_return_to_select()


func _process(_delta: float) -> void:
	if not GameManager.is_level_active:
		return
	# 实时更新锚点持有状态
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		var carrying := player._held_anchor != null
		anchors_label.text = "锚点: %s" % ("持有" if carrying else "已投出")
		anchors_label.modulate = Color.GREEN if carrying else Color.ORANGE


# ---- 信号处理 ----

func _on_level_started(level_data: LevelData) -> void:
	level_label.text = "第%d关: %s" % [level_data.level_number, level_data.level_name]
	rescued_label.text = "已救出: 0 / %d" % level_data.target_rescued
	timer_label.modulate = Color.WHITE


func _on_refugee_rescued(total: int, target: int) -> void:
	rescued_label.text = "已救出: %d / %d" % [total, target]


func _on_time_updated(remaining: float, _limit: float) -> void:
	var minutes := int(remaining) / 60
	var seconds := int(remaining) % 60
	timer_label.text = "时间: %02d:%02d" % [minutes, seconds]
	if remaining <= 10.0:
		timer_label.modulate = Color.RED
	elif remaining <= 20.0:
		timer_label.modulate = Color.ORANGE
