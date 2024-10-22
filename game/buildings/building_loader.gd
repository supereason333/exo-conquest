extends Node

var building_list := [
	preload("res://game/buildings/testing_building.tscn")
]
var ins_building_list:Array[Node2D]

const MAX_BUILDINGS := 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var id_list:Array[int]
	for i in len(building_list):
		ins_building_list.append(building_list[i].instantiate())
		if id_list.has(ins_building_list[i].building_id):
			print_debug("UNIT ID USED TWICE " + str(ins_building_list[i].building_id))
		else:
			id_list.append(ins_building_list[i].building_id)
		
		print("BUILDING LOADED " + str(ins_building_list[i].building_id) + " " + ins_building_list[i].building_name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func load_building_from_id(id:int):
	for i in len(ins_building_list):
		
		if ins_building_list[i].building_id == id: 
			return building_list[i].instantiate()
	
	return null
