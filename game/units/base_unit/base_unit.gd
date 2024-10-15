extends CharacterBody2D

var Unit_vision := preload("res://game/units/base_unit/unit_vision.tscn")

@onready var collision_shape := $CollisionShape2D
@onready var base_sprite := $Base
var vision
var health_bar:ProgressBar
var attack_timer:Timer

@export var base_speed:int
@export var base_health:float
@export var attack_cooldown:float
@export var damage:float
@export var team_id:int
@export var detect_radius:int

var peer_id:int
var path_list:Array[Vector2]
var targets:Array[Node2D]
var target:Node2D

var health:float:
	get():
		return health
	set(value):
		health = value
		health_bar.value = health / base_health * 100
		#health_bar.value = 100

enum states {STANDBY, ATTACKING, HOLD}
var cur_state := states.STANDBY

func _ready() -> void:
	var unit_vision := Unit_vision.instantiate()
	unit_vision.name = "UnitVision"
	add_child(unit_vision)
	unit_vision.get_child(0).shape = CircleShape2D.new()
	unit_vision.get_child(0).shape.radius = detect_radius
	vision = unit_vision
	vision.body_entered.connect(on_body_entered)
	vision.body_exited.connect(on_body_exited)
	
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	add_child(attack_timer)
	
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.show_percentage = false
	health_bar.size = Vector2(50, 6)
	health_bar.position = Vector2(-health_bar.size.x / 2, collision_shape.shape.size.y / 2 + 10)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.RED
	health_bar.add_theme_stylebox_override("background", style_box)
	style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.GREEN
	health_bar.add_theme_stylebox_override("fill", style_box)
	health_bar.visible = false
	health = base_health
	add_child(health_bar)
	
	var team := MultiplayerScript.get_team_from_id(team_id)
	if team:
		base_sprite.color = team.color

func _process(delta: float) -> void:
	attack_ai()
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



func on_body_entered(body:Node2D):
	if body.is_in_group("unit"):
		if body.team_id != team_id:
			targets.append(body)
			if !target:
				target = body

func on_body_exited(body:Node2D):
	if targets.has(body):
		targets.remove_at(targets.find(body))
		if target == body:
			if targets:
				target = targets[0]
			else:
				target = null

func attack_ai():
	match cur_state:
		states.STANDBY:
			if target:
				cur_state = states.ATTACKING
		states.ATTACKING:
			if target:
				if attack_timer.is_stopped():
					attack_target()
					attack_timer.start()
			else:
				cur_state = states.STANDBY
		_:
			pass

var draw_attack := false
func attack_target():
	target.on_attack(damage)
	draw_attack = true

func on_attack(damage:float):
	health -= damage
	if health <= 0:
		killed()

func killed():
	if is_in_group("selected_unit"):
		RTS.remove_from_select(self)
	queue_free()



func box_select(box: Rect2, epsteins_list: Array):
	if !is_owned_by_user(): return
	
	var self_box := Rect2(collision_shape.get_shape().get_rect().position + position, collision_shape.get_shape().get_rect().size)
	if box.intersects(self_box):
		epsteins_list.append(self)

func point_select(point: Vector2, list:Array):
	if !is_owned_by_user(): return
	
	var self_box := Rect2(collision_shape.get_shape().get_rect().position + position, collision_shape.get_shape().get_rect().size)
	if self_box.has_point(point):
		list.append(self)

func get_sprite_frame_from_rotation(rotation:float, frames:int = 16) -> float:
	return snapped(rotation / TAU * (frames - 1), 1)

func selected():
	if !is_owned_by_user(): return
	
	health_bar.show()
	add_to_group("selected_unit")

func deselected():
	health_bar.hide()
	remove_from_group("selected_unit")

func _draw():
	if is_in_group("selected_unit"):
		# Draws the selected square
		draw_rect(collision_shape.get_shape().get_rect().grow(5), Color.GREEN, false, 2)
		
		# Draws the path
		for i in len(path_list):
			if i >= 1:
				draw_line(path_list[i - 1] - position, path_list[i] - position, Color.GRAY, 1)
			else:
				draw_line(Vector2.ZERO, path_list[0] - position, Color.GRAY, 1)
			draw_circle(path_list[i] - position, 10, Color.GRAY, false, 1)
	
	if draw_attack:
		if target:
			draw_line(Vector2.ZERO, target.position - position, MultiplayerScript.get_team_from_id(team_id).color, 1)
			draw_attack = false

func is_owned_by_user() -> bool:
	if team_id == RTS.player.team_id:
		return true
	return false
