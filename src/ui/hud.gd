## HUD — 游戏内抬头显示，展示关卡信息、救援进度、倒计时和锚点数量。
extends Control

# ---- 节点引用 ----
@onready var level_label: Label = %LevelLabel
@onready var rescued_label: Label = %RescuedLabel
@onready var timer_label: Label = %TimerLabel
@onready var anchors_label: Label = %AnchorsLabel


func _ready() -> void:
	GameManager.level_started.connect(_on_level_started)
	GameManager.refugee_rescued.connect(_on_refugee_rescued)
	GameManager.anchor_placed.connect(_on_anchor_placed)
	GameManager.time_updated.connect(_on_time_updated)


# ---- 信号处理 ----

func _on_level_started(level_data: LevelData) -> void:
	level_label.text = "第%d关: %s" % [level_data.level_number, level_data.level_name]
	rescued_label.text = "已救出: 0 / %d" % level_data.target_rescued
	anchors_label.text = "锚点: 0 / %d" % level_data.anchor_limit
	timer_label.modulate = Color.WHITE


func _on_refugee_rescued(total: int, target: int) -> void:
	rescued_label.text = "已救出: %d / %d" % [total, target]


func _on_anchor_placed(used: int, max_count: int) -> void:
	anchors_label.text = "锚点: %d / %d" % [used, max_count]
	if used >= max_count:
		anchors_label.modulate = Color.RED


func _on_time_updated(remaining: float, _limit: float) -> void:
	var minutes := int(remaining) / 60
	var seconds := int(remaining) % 60
	timer_label.text = "时间: %02d:%02d" % [minutes, seconds]
	# 紧急着色
	if remaining <= 10.0:
		timer_label.modulate = Color.RED
	elif remaining <= 20.0:
		timer_label.modulate = Color.ORANGE
