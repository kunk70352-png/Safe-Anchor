## AnchorData — 锚点属性资源。协作者可创建 .tres 定义不同锚点类型。
class_name AnchorData
extends Resource

@export var anchor_name: String = "默认锚点"
@export var attraction_radius: float = 160.0
@export var shrink_speed: float = 0.0
@export var min_radius: float = 20.0
@export var speed_modifier: float = 0.0
@export var repel: bool = false
@export var texture: Texture2D
