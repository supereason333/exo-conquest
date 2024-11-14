extends Node

signal select_list_changed
signal material_changed
signal point_select(point:Vector2)
signal box_select(box:Rect2)
signal client_player_updated(_player:PlayerData)

var player:PlayerData		# Data for self client what
var game_settings:GameSettings

var materials := MaterialCost.new(0, 0, 0, 0):
	set(value):
		materials = value
		emit_signal("material_changed")

var selected_list:Array[BaseUnit]
var selected_building:BaseBuilding:
	set(value):
		if selected_building:
			selected_building.selected = false
		selected_building = value
		if selected_building:
			selected_building.selected = true

var selected_controllable := true

#var unit_loader := preload("res://game/units/unit_loader.tscn").instantiate()

const MAX_SELECT_AMOUNT := 10

func _ready() -> void:
	#add_child(unit_loader)
	set_default_player()
	load_settings()
	

func _process(delta: float) -> void:
	pass
	
	if Input.is_action_just_pressed("self_destruct"):
		if selected_controllable:
			for unit in selected_list:
				unit.kill()
			if selected_building:
				selected_building.kill()

func load_settings():			# CHANGE THIS TO ACTUALLY LOAD SETTINGS
	game_settings = ResourceLoader.load("res://menu/settings/default_settings.tres")

func set_default_player():
	player = PlayerData.new()
	player.peer_id = -1
	player.team_id = 0
	player.username = "DEFAULT PLAYER"
	
	emit_signal("client_player_updated", player)

func on_right_click(position:Vector2):
	if !selected_controllable: return
	var clicked := get_point_select(position)
	
	for unit in selected_list:
		unit.waypoint(position, clicked)

func do_point_select(point:Vector2):
	var list:Array[BaseUnit]
	var list_building:Array[BaseUnit]
	get_tree().call_group("unit", "on_point_select", point, list)
	get_tree().call_group("building", "on_point_select", point, list_building)
	if !list and !list_building:
		selected_building = null
		clear_selection(true)
		return
	
	selected_controllable = true
	if list_building:
		selected_building = list_building[0]
		selected_controllable = list_building[0].is_owned_by_user()
		clear_selection(true)
		return
	
	if list:
		if !list[0].is_owned_by_user():
			set_selection([list[0]])
			selected_controllable = false
		elif Input.is_action_pressed("shift"):
			if selected_list.has(list[0]):
				remove_selection(list[0])
			else:
				add_selection(list[0])
		else:
			set_selection([list[0]])
		
		selected_building = null
	
	emit_signal("select_list_changed")

func get_point_select(point:Vector2) -> Node2D:
	var list:Array[Node2D]
	get_tree().call_group("unit", "on_point_select", point, list)					# THIS DOSENT WORK FIX THIS
	#get_tree().call_group("building", "on_point_select", point, list)
	
	if list:
		return list[0]
	else:
		return null

func do_box_select(box:Rect2):
	var list:Array[BaseUnit]
	get_tree().call_group("unit", "on_box_select", box, list)
	if !list:
		clear_selection()
		emit_signal("select_list_changed")
		return
	
	if !selected_controllable: 
		clear_selection()
		selected_controllable = true
	
	if Input.is_action_pressed("shift"):
		for unit in list:
			add_selection(unit)
	else:
		set_selection(list)
	
	selected_building = null
	emit_signal("select_list_changed")

func add_selection(unit:BaseUnit):
	if selected_list.size() < MAX_SELECT_AMOUNT:
		if !selected_list.has(unit):
			unit.selected = true
			selected_list.append(unit)

func remove_selection(unit:BaseUnit, _signal:bool = false):
	if selected_list.has(unit):
		unit.selected = false
		selected_list.remove_at(selected_list.find(unit))
	
	if selected_building == unit:
		selected_building = null
	
	if _signal: emit_signal("select_list_changed")

func set_selection(list:Array[BaseUnit]):
	if list.size() > MAX_SELECT_AMOUNT: list.resize(MAX_SELECT_AMOUNT)
	for i in selected_list:
		i.selected = false
	selected_list = list
	for i in selected_list:
		i.selected = true

func clear_selection(_signal:bool = false):
	for i in selected_list:
		i.selected = false
	selected_list = []
	
	if _signal: emit_signal("select_list_changed")






"""
func handle_building_point_select(building:Node2D):
	if selected_building: selected_building.deselected()
	selected_building = building
	selected_building.selected()

func clear_selected_building():
	if selected_building: selected_building.deselected()
	selected_building = null

func handle_box_select(epsteins_list:Array, add:bool = false):
	if !selected_controllable:
		clear_selected()
	selected_controllable = true
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
	if !unit.is_owned_by_user():
		clear_selected()
		selected_list = [unit]
		unit.selected()
		selected_controllable = false
		emit_signal("select_list_changed")
		return
	
	selected_controllable = true
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

func on_right_click(pos:Vector2, unit:Node2D = null):
	if !selected_controllable: return
	
	for _unit in selected_list:
		_unit.on_right_click(pos, unit)


func clear_selected(_emit_signal:bool = false):
	for i in selected_list:
		i.deselected()
	
	selected_list = []
	
	if _emit_signal: emit_signal("select_list_changed")

func remove_from_select(unit):
	if selected_list.has(unit): selected_list.remove_at(selected_list.find(unit))
	
	emit_signal("select_list_changed")
	#for i in len(selected_list):
	#	if selected_list[i] == unit:
	#		selected_list.remove_at(i)
"""

func change_team(team_id:int):
	player.team_id = team_id
	clear_selection()
	selected_building = null
	emit_signal("client_player_updated", player)
	emit_signal("select_list_changed")
