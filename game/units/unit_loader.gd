extends Node

var unit_list := [
	preload("res://game/units/testing_unit.tscn"),
	preload("res://game/units/tank_unit.tscn"),
	preload("res://game/units/sniper_unit.tscn"),
	preload("res://game/units/miner_unit.tscn"),
	preload("res://game/units/marine_unit.tscn")
]

const MAX_UNITS := 100

var ins_unit_list:Array[BaseUnit]

func _ready() -> void:
	var id_list:Array[int]
	for i in len(unit_list):
		ins_unit_list.append(unit_list[i].instantiate())
		if id_list.has(ins_unit_list[i].unit_id):
			print_debug("UNIT ID USED TWICE " + str(ins_unit_list[i].unit_id))
		else:
			id_list.append(ins_unit_list[i].unit_id)
		
		print("UNIT LOADED " + str(ins_unit_list[i].unit_id) + " " + ins_unit_list[i].unit_name)

func load_unit_from_id(id:int) -> BaseUnit:
	for i in len(ins_unit_list):
		
		if ins_unit_list[i].unit_id == id: 
			return unit_list[i].instantiate()
	
	return null
