extends Camera2D

var Disp := preload("res://game/player/team_display.tscn")

@onready var game_env := $".."
@onready var team_selector := $UI/Control/DebugMenu/TeamSelector
@onready var unit_sb := $UI/Control/DebugMenu/SelectedData/UnitSelect
@onready var selected_data := $UI/Control/DebugMenu/SelectedData
@onready var debug_menu := $UI/Control/DebugMenu
@onready var building_selector := $UI/Control/DebugMenu/BuildingSelector
@onready var pause_menu := $UI/Control/PauseMenu
@onready var text_display := $UI/Control/MarginContainer/TextDisplay
@onready var text_display_label := $UI/Control/MarginContainer/TextDisplay/VBoxContainer/Label
@onready var building_placer := $UI/Control/MarginContainer/BuildingPlacer

signal add_new_building(building)

var building
var cam_mov_zone := 2
const MOVE_SPEED := 1000.0

var select_box:Rect2:
	set(value):
		value.position -= position
		select_box = value
		queue_redraw()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RTS.select_list_changed.connect(select_list_changed)
	building_selector.add_new_building.connect(on_add_building)
	building_placer.add_new_building.connect(on_add_building)
	update_team_list()
	update_selected_data()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("map_key"):
		$"UI/Control/TextureRect".visible = !$"UI/Control/TextureRect".visible
	
	handle_camera_move(delta)
	if Input.is_action_just_pressed("debug_gui"):
		debug_menu.visible = !debug_menu.visible

func update_team_list():
	for child in team_selector.get_children(): child.queue_free()
	for team in MultiplayerScript.team_list:
		var disp = Disp.instantiate()
		disp.team = team
		#disp.switch_team.connect(switch_team)
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
		
		label = Label.new()
		label.text = "Peer ID: " + str(RTS.selected_list[unit_sb.value].peer_id)
		selected_data.add_child(label)

func switch_team(team_id:int):
	RTS.change_team(team_id)
	update_team_list()

func handle_camera_move(delta:float):
	if pause_menu.visible: return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var move_vector = Vector2(0, 0)
	
	if mouse_pos.x <= cam_mov_zone or Input.is_action_pressed("cam_left"):
		move_vector.x -= 1
	
	if mouse_pos.x >= 640 - cam_mov_zone or Input.is_action_pressed("cam_right"):
		move_vector.x += 1
	
	if mouse_pos.y <= cam_mov_zone or Input.is_action_pressed("cam_up"):
		move_vector.y -= 1
	
	if mouse_pos.y >= 480 - cam_mov_zone or Input.is_action_pressed("cam_down"):
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
	emit_signal("add_new_building", building_id)

func _on_unit_select_value_changed(value: float) -> void:
	unit_sb.max_value = len(RTS.selected_list) - 1
	update_selected_data()

func set_dialogue(text:String):
	text_display_label.text = text
	text_display.show()

func _draw():
	draw_rect(select_box, RTS.game_settings.select_color, false, 2)
