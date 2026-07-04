@tool
## 关卡编辑器标记 — 在 2D 视图中显示为彩色圆点，可自由拖拽。
class_name PlacerMarker
extends Node2D

enum Category { TYPE1, TYPE2, TYPE3, REFUGEE, SAFE_HOUSE }

@export var category: Category = Category.TYPE1:
	set(v):
		category = v
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var r := 14.0
	var c := _get_color()
	draw_circle(Vector2.ZERO, r, Color(c, 0.35))
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(c, 0.8), 2.0)


func _get_color() -> Color:
	match category:
		Category.TYPE1:   return Color(0.3, 0.5, 1.0)   # 蓝 — 普通锚点
		Category.TYPE2:   return Color(0.2, 0.8, 0.3)   # 绿 — 大型锚点
		Category.TYPE3:   return Color(1.0, 0.3, 0.3)   # 红 — 驱赶锚点
		Category.REFUGEE:    return Color(0.9, 0.9, 0.9)   # 白 — NPC 出生点
		Category.SAFE_HOUSE: return Color(1.0, 0.7, 0.2)   # 橙 — 安全屋
	return Color.GRAY