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
	if selected_list.has(unit): selected_list.remove_at(selected_list.find(unit))
	#for i in len(selected_list):
	#	if selected_list[i] == unit:
	#		selected_list.remove_at(i)

func deselect_all():
	selected_list = []
	var nodes := get_tree().get_nodes_in_group("selected_unit")
	for node in nodes:
		node.deselected()
		node.remove_from_group("selected_unit")

func change_team(team_id:int):
	var has := false
	for t in MultiplayerScript.team_list: if t.id == team_id: 
		has = true
		break
	if !has: return false
	
	player.team_id = team_id
	deselect_all()
