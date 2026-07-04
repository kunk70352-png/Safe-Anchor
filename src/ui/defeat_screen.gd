## DefeatScreen — 时间耗尽且救援不足时显示。
## 展示关卡统计并提供重试选项。
extends Control

# ---- 节点引用 ----
@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var retry_button: Button = %RetryButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func display_stats(stats: Dictionary) -> void:
	visible = true
	title_label.text = "时间到！"
	title_label.modulate = Color.RED

	var rescued: int = stats.get("rescued", 0)
	var target: int = stats.get("target", 0)
	var missing := target - rescued

	stats_label.text = (
		"关卡: %s\n" % stats.get("level_name", "?") +
		"救出: %d / %d\n" % [rescued, target] +
		"还差 %d 人！" % missing
	)


func _on_retry_pressed() -> void:
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("on_retry_pressed"):
		main.on_retry_pressed()


func _on_quit_pressed() -> void:
	get_tree().quit()
