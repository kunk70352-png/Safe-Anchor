## 矿车 — 在铁轨上循环移动，可接住投掷的锚点。
class_name Minecart
extends PathFollow2D

@export var speed: float = 100.0

var _caught_anchor: Anchor = null


func _ready() -> void:
	if has_node("CatchZone"):
		$CatchZone.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	progress += speed * delta
	if _caught_anchor and is_instance_valid(_caught_anchor):
		_caught_anchor.global_position = $CatchZone.global_position


func _on_body_entered(body: Node2D) -> void:
	if _caught_anchor != null:
		return
	if body is Anchor:
		_caught_anchor = body
		_caught_anchor.get_parent().remove_child(_caught_anchor)
		add_child(_caught_anchor)
		_caught_anchor.position = Vector2.ZERO
