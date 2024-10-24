extends Camera2D

var Disp := preload("res://game/player/team_display.tscn")

@onready var game_env := $".."
@onready var team_selector := $UI/Control/DebugMenu/TeamSelector
@onready var unit_sb := $UI/Control/DebugMenu/SelectedData/UnitSelect
@onready var selected_data := $UI/Control/DebugMenu/SelectedData
@onready var debug_menu := $UI/Control/DebugMenu
@onready var building_selector := $UI/Control/DebugMenu/BuildingSelector

signal add_new_building(building)

var building
var cam_mov_zone := 2
const MOVE_SPEED := 1000.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RTS.select_list_changed.connect(select_list_changed)
	building_selector.add_new_building.connect(on_add_building)
	update_team_list()
	update_selected_data()

func _process(delta: float) -> void:
	handle_camera_move(delta)
	if Input.is_action_just_pressed("debug_gui"):
		debug_menu.visible = !debug_menu.visible

func update_team_list():
	for child in team_selector.get_children(): child.queue_free()
	for team in MultiplayerScript.team_list:
		var disp = Disp.instantiate()
		disp.team = team
		disp.switch_team.connect(switch_team)
		team_selector.add_child(disp)

func select_list_changed():
	unit_sb.max_value = len(RTS.selected_list) - 1
	update_selected_data()

func update_selected_data():
	if RTS.selected_list:
		for child in selected_data.get_children():
			if child.name != "UnitSelect":
				child.queue_free()
		var label := Label.new()
		label.text = "NAME: " + str(RTS.selected_list[unit_sb.value].unit_name)
		selected_data.add_child(label)
		
		label = Label.new()
		label.text = "Unit ID: " + str(RTS.selected_list[unit_sb.value].unit_id)
		selected_data.add_child(label)
		
		label = Label.new()
		label.text = "Base health: " + str(RTS.selected_list[unit_sb.value].base_health)
		selected_data.add_child(label)
		
		label = Label.new()
		label.text = "Health: " + str(RTS.selected_list[unit_sb.value].health)
		selected_data.add_child(label)
		
		label = Label.new()
		label.text = "Base speed: " + str(RTS.selected_list[unit_sb.value].base_speed)
		selected_data.add_child(label)
		
		label = Label.new()
		label.text = "Team ID: " + str(RTS.selected_list[unit_sb.value].team_id)
		selected_data.add_child(label)

func switch_team(team_id:int):
	RTS.change_team(team_id)
	update_team_list()

func handle_camera_move(delta:float):
	var mouse_pos = get_viewport().get_mouse_position()
	var move_vector = Vector2(0, 0)
	
	if mouse_pos.x <= cam_mov_zone:
		move_vector.x -= 1
	
	if mouse_pos.x >= 640 - cam_mov_zone:
		move_vector.x += 1
	
	if mouse_pos.y <= cam_mov_zone:
		move_vector.y -= 1
	
	if mouse_pos.y >= 480 - cam_mov_zone:
		move_vector.y += 1
	
	position += move_vector.normalized() * MOVE_SPEED * delta
	
	if position.x < limit_left:
		position.x = limit_left
	if position.x > limit_right - 640:
		position.x = limit_right - 640
	if position.y > limit_bottom - 480:
		position.y = limit_bottom - 480
	if position.y < limit_top:
		position.y = limit_top

func on_add_building(building_id:int):
	building = BuildingLoader.load_building_from_id(building_id)
	if !building: return
	building.team_id = RTS.player.team_id
	emit_signal("add_new_building", building)

func _on_unit_select_value_changed(value: float) -> void:
	unit_sb.max_value = len(RTS.selected_list) - 1
	update_selected_data()
