## AnchorData — 锚点属性资源。
## 协作者可创建 .tres 文件来定义不同的锚点类型，无需修改代码。
class_name AnchorData
extends Resource

@export var anchor_name: String = "默认锚点"
@export var attraction_radius: float = 160.0
@export var texture: Texture2D
