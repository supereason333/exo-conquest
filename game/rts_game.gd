extends Node

signal select_list_changed
signal material_changed
signal point_select(point:Vector2)
signal box_select(box:Rect2)
signal client_player_updated(_player:PlayerData)
signal settings_changed
signal core_death

const SAVE_PATH := "user://"

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
			if is_instance_valid(selected_building):
				selected_building.selected = false
		selected_building = value
		if selected_building:
			selected_building.selected = true
var base_core:BaseBuilding

var selected_controllable := true
var selected_miner:BaseUnit
var start_position:int

#var unit_loader := preload("res://game/units/unit_loader.tscn").instantiate()

const MAX_SELECT_AMOUNT := 10

func _ready() -> void:
	#add_child(unit_loader)
	set_default_player()
	load_settings()
	core_death.connect(on_core_death)
	MultiplayerScript.game_ended.connect(on_game_ended)

func _process(_delta: float) -> void:
	pass
	
	if Input.is_action_just_pressed("self_destruct"):
		if selected_controllable:
			for unit in selected_list:
				unit.kill()
			if selected_building:
				selected_building.kill()

func load_settings():
	if FileAccess.file_exists(SAVE_PATH + "settings.tres"):
		game_settings = ResourceLoader.load(SAVE_PATH + "settings.tres")
		return
	game_settings = ResourceLoader.load("res://menu/settings/default_settings.tres")
	ResourceSaver.save(game_settings, SAVE_PATH + "settings.tres")

func set_default_player():
	player = PlayerData.new()
	player.peer_id = -1
	player.team_id = 0
	player.username = "DEFAULT PLAYER"
	
	emit_signal("client_player_updated", player)

func on_right_click(position:Vector2):
	if !base_core: return
	
	if !selected_controllable: return
	var clicked := get_point_select(position)
	
	for unit in selected_list:
		unit.waypoint(position, clicked, Input.is_action_pressed("shift"))

func do_point_select(point:Vector2):
	if !base_core: return
	
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
	get_tree().call_group("unit", "on_point_select", point, list)
	#get_tree().call_group("building", "on_point_select", point, list)
	
	if list:
		return list[0]
	else:
		return null

func do_box_select(box:Rect2):
	if !base_core: return
	
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
	if !base_core: return
	
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
	if !base_core: return
	
	if list.size() > MAX_SELECT_AMOUNT: list.resize(MAX_SELECT_AMOUNT)
	for i in selected_list:
		if is_instance_valid(i):
			i.selected = false
	selected_list = list
	for i in selected_list:
		i.selected = true

func clear_selection(_signal:bool = false):
	for i in selected_list:
		if is_instance_valid(i):
			i.selected = false
	selected_list = []
	
	if _signal: emit_signal("select_list_changed")

func pre_game_init():
	get_tree().change_scene_to_file("res://game/game_environment.tscn")

@rpc
func set_start_pos(pos:int):
	start_position = pos

func on_core_death():
	clear_selection()
	selected_controllable = false
	selected_building = null

func on_game_ended():
	pass

func change_team(team_id:int):
	player.team_id = team_id
	clear_selection()
	selected_building = null
	emit_signal("client_player_updated", player)
	emit_signal("select_list_changed")
