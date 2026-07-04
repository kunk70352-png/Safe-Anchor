## AnchorData — 锚点属性资源。创建 .tres 可定义不同的锚点类型。
class_name AnchorData
extends Resource

## 锚点名称
@export var anchor_name: String = "默认锚点"
## 吸引半径（像素）
@export var attraction_radius: float = 160.0
## 每秒缩小像素（0=不缩小）
@export var shrink_speed: float = 0.0
## 缩小下限
@export var min_radius: float = 20.0
## 难民速度加成（正=加速，负=减速）
@export var speed_modifier: float = 0.0
## 驱赶模式
@export var repel: bool = false
## 贴图
@export var texture: Texture2D
