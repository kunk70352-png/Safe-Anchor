extends PathFollow2D

func _physics_process(delta: float) -> void:
	progress += 200.0 * delta    # 200 = 移动速度
