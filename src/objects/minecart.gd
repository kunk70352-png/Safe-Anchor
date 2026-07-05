## 矿车 — 在铁轨上循环移动，可接住投掷的锚点。
class_name Minecart
extends PathFollow2D

@export var speed: float = 100.0

var _caught_anchor: Anchor = null


func _ready() -> void:
	add_to_group("minecarts")
	if has_node("CatchZone") and not $CatchZone.area_entered.is_connected(_on_area_entered):
		$CatchZone.area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	progress += speed * delta
	if _caught_anchor and is_instance_valid(_caught_anchor):
		_caught_anchor.global_position = $CatchZone.global_position


func _on_area_entered(area: Area2D) -> void:
	if _caught_anchor != null:
		return
	var parent := area.get_parent()
	if parent is Anchor:
		_caught_anchor = parent
		call_deferred("_catch_anchor")


func _catch_anchor() -> void:
	if not _caught_anchor or not is_instance_valid(_caught_anchor):
		return
	var old_parent := _caught_anchor.get_parent()
	if old_parent:
		old_parent.remove_child(_caught_anchor)
	add_child(_caught_anchor)
	_caught_anchor.position = Vector2.ZERO


func get_caught_anchor() -> Anchor:
	if _caught_anchor and is_instance_valid(_caught_anchor):
		return _caught_anchor
	return null


func release_anchor() -> void:
	_caught_anchor = null
