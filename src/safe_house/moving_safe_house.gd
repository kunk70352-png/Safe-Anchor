## 移动安全屋 — 沿 Path2D 移动，超出地图则失败。
class_name MovingSafeHouse
extends SafeHouse

@export var speed: float = 60.0
@export var path_node: NodePath

var _path_follow: PathFollow2D


func _ready() -> void:
	super._ready()
	if path_node.is_empty():
		return
	var path := get_node(path_node) as Path2D
	if path:
		_path_follow = PathFollow2D.new()
		path.add_child(_path_follow)
		_path_follow.loop = false


func _physics_process(delta: float) -> void:
	if _path_follow:
		_path_follow.progress += speed * delta
		global_position = _path_follow.global_position
		# 超出地图边界 → 失败
		var pos := global_position
		if pos.x < -50 or pos.x > 1970 or pos.y < -50 or pos.y > 1130:
			var stats := {"level": 0, "level_name": "安全屋丢失"}
			if GameManager.current_level_data:
				stats = {"level": GameManager.current_level_data.level_number, "level_name": GameManager.current_level_data.level_name}
			GameManager.level_failed.emit(stats)
