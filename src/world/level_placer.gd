@tool
## 关卡布局编辑器 — 可视化管理锚点和 NPC 出生位置。
## 打开地图场景 → 拖拽彩色标记 → Ctrl+S 保存场景 → 自动写入 .tres。
class_name LevelPlacer
extends Node2D


func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()
		return
	var path := _guess_tres_path()
	if path == "":
		return
	var ld := load(path) as LevelData
	if ld and _marker_count() == 0:
		_load_positions(ld, path)


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		var path := _guess_tres_path()
		if path != "":
			_save_positions(path)


func _process(_delta: float) -> void:
	pass


# ---- 路径推断 ----

func _guess_tres_path() -> String:
	if not Engine.is_editor_hint():
		return ""
	var root := get_tree().edited_scene_root
	if not root:
		return ""
	var scene_path := root.scene_file_path
	if scene_path == "":
		return ""
	var base := scene_path.get_file().trim_suffix("_map.tscn")
	if base == scene_path.get_file():
		return ""
	return "res://resources/levels/" + base + ".tres"


func _marker_count() -> int:
	var n := 0
	for c in get_children():
		if c is PlacerMarker:
			n += 1
	return n


# ---- 加载 / 保存 ----

func _load_positions(ld: LevelData, path: String) -> void:
	_clear_markers()
	for pos in ld.type1_positions:
		_add_marker(PlacerMarker.Category.TYPE1, pos)
	for pos in ld.type2_positions:
		_add_marker(PlacerMarker.Category.TYPE2, pos)
	for pos in ld.type3_positions:
		_add_marker(PlacerMarker.Category.TYPE3, pos)
	for pos in ld.refugee_spawn_positions:
		_add_marker(PlacerMarker.Category.REFUGEE, pos)
	_add_marker(PlacerMarker.Category.SAFE_HOUSE, ld.safe_house_position)
	print_rich("[color=green][LevelPlacer] 已从 ", path, " 加载 ", _marker_count(), " 个标记[/color]")


func _save_positions(path: String) -> void:
	var ld := load(path) as LevelData
	if not ld:
		return

	var t1: Array[Vector2] = []
	var t2: Array[Vector2] = []
	var t3: Array[Vector2] = []
	var ref: Array[Vector2] = []

	for c in get_children():
		if not (c is PlacerMarker):
			continue
		var m := c as PlacerMarker
		match m.category:
			PlacerMarker.Category.TYPE1:      t1.append(m.position)
			PlacerMarker.Category.TYPE2:      t2.append(m.position)
			PlacerMarker.Category.TYPE3:      t3.append(m.position)
			PlacerMarker.Category.REFUGEE:    ref.append(m.position)
			PlacerMarker.Category.SAFE_HOUSE: ld.safe_house_position = m.position

	ld.type1_positions = t1
	ld.type2_positions = t2
	ld.type3_positions = t3
	ld.refugee_spawn_positions = ref
	ResourceSaver.save(ld, path)
	print_rich("[color=green][LevelPlacer] 已保存到 ", path, " (锚点:", t1.size() + t2.size() + t3.size(), " NPC:", ref.size(), ")[/color]")


# ---- 标记管理 ----

func _clear_markers() -> void:
	for c in get_children():
		if c is PlacerMarker:
			remove_child(c)
			c.queue_free()


func _add_marker(cat: PlacerMarker.Category, pos: Vector2) -> void:
	var m := PlacerMarker.new()
	m.category = cat
	m.position = pos
	add_child(m)
	if Engine.is_editor_hint():
		var root := get_tree().edited_scene_root
		if root:
			m.owner = root
