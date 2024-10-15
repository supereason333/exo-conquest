extends Camera2D

var Disp := preload("res://game/player/team_display.tscn")

@onready var game_env := $".."
@onready var team_selector := $UI/Control/TeamSelector

var cam_mov_zone := 10
const MOVE_SPEED := 1000.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_team_list()

func update_team_list():
	for child in team_selector.get_children(): child.queue_free()
	for team in MultiplayerScript.team_list:
		var disp = Disp.instantiate()
		disp.team = team
		disp.switch_team.connect(switch_team)
		team_selector.add_child(disp)

func switch_team(team_id:int):
	RTS.change_team(team_id)
	update_team_list()

func _process(delta):
	handle_camera_move(delta)

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
