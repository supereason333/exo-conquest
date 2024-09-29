extends CharacterBody2D

@onready var collision_shape := $CollisionShape2D
@onready var base_sprite := $Base

@export var base_speed:int
@export var team_id:int

var peer_id:int
var path_list:Array[Vector2]

func _ready() -> void:
	#RTS.point_select.connect(point_select)
	#RTS.box_select.connect(box_select)
	var team := MultiplayerScript.get_team_from_id(team_id)
	if team:
		base_sprite.color = team.color

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("unit_move") and is_in_group("selected_unit"):
		if Input.is_action_pressed("shift"):
			add_path_point(get_global_mouse_position())
		else:
			add_path_point(get_global_mouse_position(), true)
	
	queue_redraw()

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	
	if path_list:
		movement()
		move_and_slide()

func movement():
	var dist_to_target:Vector2 = path_list[0] - position
	
	velocity += dist_to_target.normalized() * base_speed
	
	base_sprite.frame = get_sprite_frame_from_rotation(dist_to_target.angle() + PI)
	
	if dist_to_target.length_squared() <= 1000:
		path_list.remove_at(0)

func add_path_point(pos:Vector2, replace_list:bool = false):
	if replace_list:
		path_list = []
		path_list.append(pos)
	else:
		path_list.append(pos)



func box_select(box: Rect2, epsteins_list: Array):
	var self_box := Rect2(collision_shape.get_shape().get_rect().position + position, collision_shape.get_shape().get_rect().size)
	if box.intersects(self_box):
		epsteins_list.append(self)

func point_select(point: Vector2, list:Array):
	var self_box := Rect2(collision_shape.get_shape().get_rect().position + position, collision_shape.get_shape().get_rect().size)
	if self_box.has_point(point):
		list.append(self)

func get_sprite_frame_from_rotation(rotation:float, frames:int = 16) -> float:
	return snapped(rotation / TAU * (frames - 1), 1)

func selected():
	add_to_group("selected_unit")

func deselected():
	remove_from_group("selected_unit")

func _draw():
	if is_in_group("selected_unit"):
		# Draws the selected square
		draw_rect(collision_shape.get_shape().get_rect().grow(5), Color.GREEN, false, 2)
		
		# Draws the path
		for i in len(path_list):
			if i >= 1:
				draw_line(path_list[i - 1] - position, path_list[i] - position, Color.GRAY, 2)
			else:
				draw_line(Vector2.ZERO, path_list[0] - position, Color.GRAY, 2)
			draw_circle(path_list[i] - position, 10, Color.GRAY, false, 2)
