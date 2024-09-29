extends Node

signal select_list_changed

signal point_select(point:Vector2)
signal box_select(box:Rect2)

@export var player:PlayerData

# Materials
@export var material_list:Array[int]

var deselect_queue:Array
var called_deselect := false
var selected_list:Array
const MAX_SELECT_AMOUNT := 4

func _ready() -> void:
	set_default_player()

func _process(delta: float) -> void:
	pass
	#print(selected_list)

func set_default_player():
	player = PlayerData.new()
	player.peer_id = 1
	player.team_id = 0
	player.username = "DEFAULT PLAYER"

func handle_box_select(epsteins_list:Array, add:bool = false):
	if add:
		for unit in epsteins_list:
			if !selected_list.has(unit) and selected_list.size() < MAX_SELECT_AMOUNT:
				selected_list.append(unit)
		
	else:
		for unit in selected_list:
			unit.deselected()
		
		if epsteins_list.size() > MAX_SELECT_AMOUNT:
			epsteins_list.resize(MAX_SELECT_AMOUNT)
		selected_list = epsteins_list
	
	for unit in selected_list:
		unit.selected()

func handle_point_select(unit, add:bool = false):
	if add:
		if !selected_list.has(unit) and selected_list.size() < MAX_SELECT_AMOUNT:
			selected_list.append(unit)
		elif selected_list.has(unit):
			for i in selected_list.size():
				if selected_list[i] == unit:
					selected_list[i].deselected()
					selected_list.remove_at(i)
					break
		
	else:
		for a in selected_list:
			a.deselected()
		selected_list = []
		selected_list.append(unit)
	
	for a in selected_list:
		a.selected()

func clear_selected():
	for i in selected_list:
		i.deselected()
	
	selected_list = []

func remove_from_select(unit):
	for i in len(selected_list):
		if selected_list[i] == unit:
			selected_list.remove_at(i)
	
