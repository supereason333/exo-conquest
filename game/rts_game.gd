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
var selected_building:Node2D

var unit_loader := preload("res://game/units/unit_loader.tscn").instantiate()

const MAX_SELECT_AMOUNT := 10

func _ready() -> void:
	add_child(unit_loader)
	set_default_player()

func _process(delta: float) -> void:
	pass
	#print(selected_list)

func set_default_player():
	player = PlayerData.new()
	player.peer_id = 1
	player.team_id = 0
	player.username = "DEFAULT PLAYER"

func handle_building_point_select(building:Node2D):
	if selected_building: selected_building.deselected()
	selected_building = building
	selected_building.selected()

func clear_selected_building():
	if selected_building: selected_building.deselected()
	selected_building = null

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
	
	emit_signal("select_list_changed")

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
	
	emit_signal("select_list_changed")

func clear_selected():
	for i in selected_list:
		i.deselected()
	
	selected_list = []

func remove_from_select(unit):
	if selected_list.has(unit): selected_list.remove_at(selected_list.find(unit))
	#for i in len(selected_list):
	#	if selected_list[i] == unit:
	#		selected_list.remove_at(i)

func change_team(team_id:int):
	var has := false
	for t in MultiplayerScript.team_list: if t.id == team_id: 
		has = true
		break
	if !has: return false
	
	player.team_id = team_id
	clear_selected()
	clear_selected_building()
