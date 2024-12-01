extends Node2D

var Map := preload("res://game/resources/maps/testing_map.tscn").instantiate()

var box_select := false
var mouse_down := false
var box:Rect2

@onready var map := $Map
@onready var tile_map := $Map/BaseTiles
@onready var data_tile_map := $Map/DataTiles
@onready var player := $PlayerControl
@onready var building_detector := $BuildingDetector
@onready var bgm_player := $BGM
@onready var spawnpoints := $Map/Spawnpoints
@onready var multiplayer_spwner:MultiplayerSpawner
var tutorial:Node

var placing_building := false
var building:BaseBuilding
var build_draw_rects:Array[Rect2]
var can_build:bool

var next_build_id := 0
var next_unit_id := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if has_node("Tutorial"):
		tutorial = $Tutorial
		tutorial.init()
	
	if has_node("MultiplayerSpawner"):
		multiplayer_spwner = $"MultiplayerSpawner"
	
	var limit:Vector2 = tile_map.get_used_rect().size
	limit *= Vector2(tile_map.tile_set.tile_size)
	
	player.limit_right = limit.x
	player.limit_bottom = limit.y
	
	player.add_new_building.connect(start_place_building)
	
	_on_bgm_finished()
	
	MultiplayerScript.game_ended.connect(on_game_ended)
	
	if MultiplayerScript.game_running:
		pre_game_init()

func _process(_delta: float) -> void:
	queue_redraw()
	#data_viewer_code()
	if Input.is_action_just_pressed("unit_move"):
		RTS.on_right_click(get_global_mouse_position())
	if placing_building:
		if Input.is_action_just_pressed("place"):
			if can_build:
				building.position = Vector2i(get_global_mouse_position() / 32) * 32 + building.building_size * 32 / 2
				add_building(building)
				building = null
				placing_building = false
		elif Input.is_action_just_pressed("cancel"):
			placing_building = false

func game_init():
	pass

"""func data_viewer_code():
	var viewer_tile:Vector2i = data_tile_map.local_to_map(data_tile_map.get_local_mouse_position())
	var viewer_pos:Vector2 = viewer_tile * data_tile_map.tile_set.tile_size
	var tile = data_tile_map.get_cell_tile_data(viewer_tile)
	
	if tile:
		data_viewer.material_label.text = tile.get_custom_data("Material name") + " - " + str(tile.get_custom_data("Material ID"))
		if tile.get_custom_data("Not buildable"):
			data_viewer.buildable_color.color = Color(1, 0, 0)
	else:
		data_viewer.material_label.text = "material"
		data_viewer.buildable_color.color = Color(0, 1, 0)
	
	data_viewer.position = viewer_pos"""

func add_unit(unit:BaseUnit):
	if !unit: return
	if !multiplayer.is_server():
		rpc_id(1, "rpc_add_unit", unit.unit_id, unit.position, multiplayer.get_unique_id(), unit.waypoints)
		return
	next_unit_id += 1
	if unit.peer_id == 0:
		unit.peer_id = multiplayer.get_unique_id()
	if unit.team_id == 0:
		unit.team_id = MultiplayerScript.get_player_from_peer_id(multiplayer.get_unique_id()).team_id
	unit.name = "unit_" + str(unit.peer_id) + "_" + str(next_unit_id)
	add_child(unit)

@rpc("any_peer")
func rpc_add_unit(unit_id:int, _position:Vector2, peer_id:int, waypoints:Array):
	if !multiplayer.is_server(): return
	var unit := UnitLoader.load_unit_from_id(unit_id)
	unit.position = _position
	unit.team_id = MultiplayerScript.get_player_from_peer_id(peer_id).team_id
	unit.peer_id = peer_id
	unit.waypoints = waypoints
	add_unit(unit)

@rpc("any_peer")
func rpc_add_building(building_id:int, _position:Vector2, peer_id:int):
	if !multiplayer.is_server(): return
	var new_building := BuildingLoader.load_building_from_id(building_id)
	new_building.position = _position
	new_building.team_id = MultiplayerScript.get_player_from_peer_id(peer_id).team_id
	new_building.peer_id = peer_id
	add_building(new_building)

func add_building(build:BaseBuilding):
	if !build: return
	if !multiplayer.is_server():
		rpc_id(1, "rpc_add_building", build.unit_id, build.position, multiplayer.get_unique_id())
		return
	if build.peer_id == 0:
		build.peer_id = multiplayer.get_unique_id()
	next_build_id += 1
	if build.team_id == 0:
		build.team_id = MultiplayerScript.get_player_from_peer_id(multiplayer.get_unique_id()).team_id
	if build.unit_id == 1:
		build.name = "core_" + str(build.peer_id) + "_" + str(next_build_id)
	else:
		build.name = "building_" + str(build.peer_id) + "_" + str(next_build_id)
	add_child(build)
	return
	

func start_place_building(building_id:int):
	placing_building = true
	building = BuildingLoader.load_building_from_id(building_id)
	if !building: return
	build_draw_rects = []
	building_detector.get_child(0).shape.size = building.building_size * 32
	var rec_shape := RectangleShape2D.new()
	rec_shape.size = building_detector.get_child(0).shape.get_rect().grow(-1).size
	building_detector.get_child(0).shape = rec_shape
	
	for x in building.building_size.x:
		for y in building.building_size.y:
			var rect = Rect2(Vector2(x, y) * 32, Vector2(32, 32))
			build_draw_rects.append(rect)
		
	placing_building = true

func _draw():
	if build_draw_rects and placing_building:
		var detector_build_check := true
		var build_check := true
		building_detector.position = Vector2i(get_global_mouse_position() / 32) * 32 + building.building_size * 32 / 2
		var 𝓬𝓾𝓻𝓼𝓮_𝓸𝓯_𝓽𝓱𝓮_𝓷𝓲𝓵𝓮 = building_detector.get_overlapping_bodies()
		for 𓀔𓀇𓀅𓀋𓀡𓀡𓀕𓀠𓀧𓀨𓀣𓀷𓀷𓀿𓀿𓁀𓁶𓁰 in 𝓬𝓾𝓻𝓼𝓮_𝓸𝓯_𝓽𝓱𝓮_𝓷𝓲𝓵𝓮:
			if 𓀔𓀇𓀅𓀋𓀡𓀡𓀕𓀠𓀧𓀨𓀣𓀷𓀷𓀿𓀿𓁀𓁶𓁰.is_in_group("building") or 𓀔𓀇𓀅𓀋𓀡𓀡𓀕𓀠𓀧𓀨𓀣𓀷𓀷𓀿𓀿𓁀𓁶𓁰.is_in_group("unit"):
				detector_build_check = false
				build_check = false
		
		for rect in build_draw_rects:
			var tile_build_check := true
			rect.position += Vector2(data_tile_map.local_to_map(get_global_mouse_position())) * 32
			var tile = data_tile_map.get_cell_tile_data(data_tile_map.local_to_map(rect.position))
			if tile:
				if tile.get_custom_data("Not buildable"):
					tile_build_check = false
			
			if RTS.selected_miner and is_instance_valid(RTS.selected_miner):
				if rect.position.distance_squared_to(RTS.selected_miner.position) >= 40000:
					tile_build_check = false
			else:
				placing_building = false
			
			if tile_build_check and detector_build_check:
				draw_rect(rect, Color.LIGHT_GREEN * Color(1, 1, 1, 0.5))
			else:
				draw_rect(rect, Color.LIGHT_CORAL * Color(1, 1, 1, 0.5))
				build_check = false
		
		if build_check:
			can_build = true
		else:
			can_build = false

func _unhandled_input(event: InputEvent) -> void:
	if !is_inside_tree(): return
	if event is InputEventMouseButton:
		if event.button_index == 1:
			mouse_down = event.pressed
			if event.pressed:
				box.position = event.position + player.position
				box_select = false
			else:		# When user lets go of mouse
				player.select_box = Rect2(0, 0, 0, 0)
				box = box.abs()
				if !box_select:		# A click ( Where the selection code should be executed from )
					RTS.do_point_select(event.position + player.position)
					#RTS.emit_signal("point_select", event.position + player.position)
					#var point_select_list:Array[BaseUnit]
					#var building_point_select_list:Array
					#get_tree().call_group("unit", "on_point_select", event.position + player.position, point_select_list)
					#if point_select_list:
						#RTS.handle_point_select(point_select_list[0], Input.is_action_pressed("shift"))
						#RTS.clear_selected_building()
					#else:
						#RTS.clear_selected(true)
						#get_tree().call_group("building", "point_select", event.position + player.position, building_point_select_list)
						#if building_point_select_list:
						#	RTS.handle_building_point_select(building_point_select_list[0])
						#else:
						#	RTS.clear_selected_building()
					
					print("CLICK")
				else:				# A box select
					RTS.do_box_select(box)
					#RTS.emit_signal("box_select", box)
					#var box_select_list:Array
					#get_tree().call_group("unit", "box_select", box, box_select_list)
					#if box_select_list:
					#	RTS.handle_box_select(box_select_list, Input.is_action_pressed("shift"))
					#	RTS.clear_selected_building()
					#else:
					#	RTS.clear_selected(true)
					#	RTS.clear_selected_building()
					
					#player.select_box = Rect2(0, 0, 0, 0)
					print("BOX SELECT")
					
				box_select = false
	elif event is InputEventMouseMotion:
		if mouse_down:	#mouse_down
			box.end = event.position + player.position
			if box.size.length_squared() >= 50:		# Not a click (box select)
				box_select = true
			player.select_box = box

# literaly spaghetti code

func _on_bgm_finished() -> void:
	bgm_player.stream = AudioManager.BGM.get_random()
	bgm_player.play()

func pre_game_init():
	if multiplayer.is_server():
		var i = 1
		for _player in MultiplayerScript.player_list:
			var core = BuildingLoader.load_building_from_id(1)
			core.team_id = _player.team_id
			core.peer_id = _player.peer_id
			var point = spawnpoints.find_child(str(i))
			if point:
				core.position = point.position
				if _player.peer_id == multiplayer.get_unique_id():
					set_player_pos(point.position)
					RTS.base_core = core
				else:
					rpc_id(_player.peer_id, "set_player_pos", point.position)
			else:
				printerr("Not found spawnpoint " + str(i))
			MultiplayerScript.core_list.append(core)
			core.death.connect(MultiplayerScript.core_death)
			for x in 3:
				var miner := UnitLoader.load_unit_from_id(4)
				miner.position = point.position + Vector2(20 * x, 100)
				miner.team_id = _player.team_id
				miner.peer_id = _player.peer_id
				add_child(miner, true)
			add_building(core)
			i += 1
		return
	
	return
	

func on_game_ended():
	if !multiplayer.is_server(): return
	for child in get_children():
		if child.has_method("despawn"):
			child.despawn()

@rpc
func set_player_pos(_position:Vector2):
	player.position = _position - Vector2(320, 240)

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	print(node.name.split("_"))
	if node is BaseBuilding:
		if node.name.split("_")[0] == "core" and node.name.split("_")[1] == str(multiplayer.get_unique_id()):
			RTS.base_core = node
			print("BASE CORE SET FOR " + str(multiplayer.get_unique_id()))
