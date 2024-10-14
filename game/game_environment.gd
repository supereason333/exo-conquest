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

func _process(delta: float) -> void:
	unit_move()
	
	queue_redraw()
	data_viewer_code()

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

func unit_move():
	if Input.is_action_just_pressed("unit_move"):
		if Input.is_action_pressed("shift"):
			#get_tree().call_group("selected_unit", "add_target", get_global_mouse_position(), false)
			#for unit in Player.selected_list: unit.add_path_point(get_global_mouse_position(), false)
			return
		
		#get_tree().call_group("selected_unit", "add_target", get_global_mouse_position(), true)
		#for unit in Player.selected_list: unit.add_path_point(get_global_mouse_position(), true)

func _draw():
	if box_select:
		draw_rect(box, Color.GREEN, false, 2)

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
					get_tree().call_group("unit", "point_select", event.position + player.position, point_select_list)
					if point_select_list:
						RTS.handle_point_select(point_select_list[0], Input.is_action_pressed("shift"))
					else:
						RTS.clear_selected()
					
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
