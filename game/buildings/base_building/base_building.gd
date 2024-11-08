extends BaseUnit
class_name BaseBuilding

@export var building_size:Vector2i
@export var actions:Array[Callable]

var map_position:Vector2i

func _ready() -> void:
	collision_shape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(building_size * 32)
	collision_shape.shape = rect_shape
	add_child(collision_shape)
	
	super()
	
	remove_from_group("unit")
	add_to_group("building")
	frozen = true

func on_box_select(box:Rect2, list:Array[BaseUnit]):
	pass
