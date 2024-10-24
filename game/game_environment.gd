extends Node2D

var Map := preload("res://game/resources/maps/testing_map.tscn").instantiate()

var box_select := false
var mouse_down := false
var box:Rect2

var map
var tile_map
var data_tile_map
@onready var player := $PlayerControl
@onready var data_viewer := $TileDataViewer
@onready var building_detector := $BuildingDetector

var placing_building := false
var building
var build_draw_rects:Array[Rect2]
var can_build:bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(Map)
	map = get_child(-1)
	move_child(map, 0)
	map.name = "Map"
	
	tile_map = $Map/BaseTiles
	data_tile_map = $Map/DataTiles
	
	var limit:Vector2 = tile_map.get_used_rect().size
	limit *= Vector2(tile_map.tile_set.tile_size)
	
	player.limit_right = limit.x
	player.limit_bottom = limit.y
	
	player.add_new_building.connect(add_building)

func _process(delta: float) -> void:
	queue_redraw()
	data_viewer_code()
	if placing_building:
		if Input.is_action_just_pressed("mouse_click"):
			if can_build:
				building.position = Vector2i(get_global_mouse_position() / 32) * 32 + building.size * 32 / 2
				add_child(building)
				placing_building = false

func data_viewer_code():
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
	
	data_viewer.position = viewer_pos

func add_unit(unit):
	if !unit: return
	add_child(unit)

func add_building(build):
	if !build: return
	building = build
	build_draw_rects = []
	building_detector.get_child(0).shape.size = build.size * 32
	var rec_shape := RectangleShape2D.new()
	rec_shape.size = building_detector.get_child(0).shape.get_rect().grow(-1).size
	building_detector.get_child(0).shape = rec_shape
	
	for x in build.size.x:
		for y in build.size.y:
			var rect = Rect2(Vector2(x, y) * 32, Vector2(32, 32))
			build_draw_rects.append(rect)
		
	placing_building = true

func _draw():
	if box_select:
		draw_rect(box, Color.GREEN, false, 2)
	if build_draw_rects and placing_building:
		var b := true
		for rect in build_draw_rects:
			var bb := true
			rect.position += Vector2(data_tile_map.local_to_map(get_global_mouse_position())) * 32
			var tile = data_tile_map.get_cell_tile_data(data_tile_map.local_to_map(rect.position))
			if tile:
				if tile.get_custom_data("Not buildable"):
					bb = false
			
			building_detector.position = rect.position - Vector2(16, 0)
			var 𝓬𝓾𝓻𝓼𝓮_𝓸𝓯_𝓽𝓱𝓮_𝓷𝓲𝓵𝓮 = building_detector.get_overlapping_bodies()
			for 𓀔𓀇𓀅𓀋𓀡𓀡𓀕𓀠𓀧𓀨𓀣𓀷𓀷𓀿𓀿𓁀𓁶𓁰 in 𝓬𝓾𝓻𝓼𝓮_𝓸𝓯_𝓽𝓱𝓮_𝓷𝓲𝓵𝓮:
				if 𓀔𓀇𓀅𓀋𓀡𓀡𓀕𓀠𓀧𓀨𓀣𓀷𓀷𓀿𓀿𓁀𓁶𓁰.is_in_group("building"):
					bb = false
			
			if bb:
				draw_rect(rect, Color.LIGHT_GREEN * Color(1, 1, 1, 0.5))
			else:
				draw_rect(rect, Color.LIGHT_CORAL * Color(1, 1, 1, 0.5))
				b = false
		
		if b:
			can_build = true
		else:
			can_build = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			mouse_down = event.pressed
			
			if mouse_down:
				box.position = event.position + player.position
				box_select = false
			else:		# When user lets go of mouse
				box = box.abs()
				
				if !box_select:		# A click ( Where the selection code should be executed from )
					RTS.emit_signal("point_select", event.position + player.position)
					var point_select_list:Array
					var building_point_select_list:Array
					get_tree().call_group("unit", "point_select", event.position + player.position, point_select_list)
					if point_select_list:
						RTS.handle_point_select(point_select_list[0], Input.is_action_pressed("shift"))
						RTS.clear_selected_building()
					else:
						RTS.clear_selected()
						get_tree().call_group("building", "point_select", event.position + player.position, building_point_select_list)
						if building_point_select_list:
							RTS.handle_building_point_select(building_point_select_list[0])
						else:
							RTS.clear_selected_building()
					
					print("CLICK")
				else:				# A box select
					RTS.emit_signal("box_select", box)
					var box_select_list:Array
					get_tree().call_group("unit", "box_select", box, box_select_list)
					if box_select_list:
						RTS.handle_box_select(box_select_list, Input.is_action_pressed("shift"))
					else:
						RTS.clear_selected()
					
					print("BOX SELECT")
					
				box_select = false
	elif event is InputEventMouseMotion:
		if mouse_down:
			box.end = event.position + player.position
			if box.size.length_squared() >= 50:		# Not a click (box select)
				box_select = true

# literaly spaghetti code
