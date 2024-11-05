extends CharacterBody2D
class_name BaseUnit

signal death

var Unit_vision := preload("res://game/units/base_unit/unit_vision.tscn")
var Explosion := preload("res://game/resources/particles/explosion.png")
var Explosion_sound := preload("res://game/resources/sound/effects/explosion.wav")

var team_id:int
var waypoints:Array[Vector2]
var selected := false:
	set(value):
		health_bar.visible = value
		selected = value
		queue_redraw()
	get:
		return selected
var vision_list:Array[Node2D]
var dying := false

@export var unit_name:String
@export var unit_id:int

@export_group("Movement")
@export var base_speed:int

@export_group("Attack")
@export var base_health:float
@export var attack_damage:float
@export var attack_cooldown:float
@export var attack_range:int
@export var vision_radius:int
@export var agression_distance:int	# Agression distance

@export_group("Sprite")
@export var color_sprite_frames:SpriteFrames
@export var base_sprite_frames:SpriteFrames
@export var display_icon:CompressedTexture2D = preload("res://game/resources/sprites/placeholder/32x.png")

@export_group("Other")
@export var dummy:bool = false

var health:float:
	get():
		return health
	set(value):
		if value <= 0:
			kill()
			emit_signal("death")
		health = value
		health_bar.value = health / base_health * 100

@onready var collision_shape := $CollisionShape2D
var vision_area:Area2D = Area2D.new()
var health_bar:ProgressBar = ProgressBar.new()
var attack_timer:Timer = Timer.new()
var base_sprite := AnimatedSprite2D.new()
var color_sprite := AnimatedSprite2D.new()

enum states {STANDBY, ATTACKING, ATTACK_CHASE, HOLD}
var cur_state:int = states.STANDBY

func _ready() -> void:
	base_sprite.sprite_frames = base_sprite_frames
	color_sprite.sprite_frames = color_sprite_frames
	base_sprite.frame_changed.connect(sprite_frame_changed)
	add_child(base_sprite)
	base_sprite.add_child(color_sprite)
	
	if dummy: 
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		return
	
	set_collision_layer_value(2, true)
	add_to_group("unit")
	
	var vision_area_shape := CollisionShape2D.new()
	vision_area_shape.shape = CircleShape2D.new()
	vision_area_shape.shape.radius = vision_radius
	vision_area.add_child(vision_area_shape)
	vision_area.set_collision_mask_value(1, false)
	vision_area.set_collision_mask_value(2, true)
	vision_area.body_entered.connect(on_body_enter_vision)
	vision_area.body_exited.connect(on_body_exit_vision)
	add_child(vision_area)
	
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
	
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	add_child(attack_timer)
	
	set_team(team_id)

func _process(delta: float) -> void:
	if dummy: return
	
	if vision_list:
		attack_ai()
	
	pass

func _physics_process(delta: float) -> void:
	if dummy: return
	if dying: return
	
	movement(delta)

func _draw():
	if dummy: return
	if dying: return
	
	if selected:
		if is_owned_by_user(): draw_rect(collision_shape.shape.get_rect().grow(4), RTS.game_settings.select_color, false)
		else: draw_rect(collision_shape.shape.get_rect().grow(4), RTS.game_settings.enemy_color, false)

func movement(delta:float):
	if waypoints:
		if position.distance_squared_to(waypoints[0]) <= 100:
			waypoints.remove_at(0)
			if !waypoints: return
		velocity = Vector2.ZERO
		var direction := (waypoints[0] - position).normalized()
		velocity += direction * base_speed
		base_sprite.frame = get_sprite_frame_from_rotation(direction.angle())
		move_and_slide()

func set_team(_team_id:int):
	if dummy: return
	if dying: return
	
	team_id = _team_id
	var team := MultiplayerScript.get_team_from_id(team_id)
	if team:
		color_sprite.modulate = team.color

func sprite_frame_changed():
	color_sprite.frame = base_sprite.frame

func get_sprite_frame_from_rotation(rotation:float, frames:int = 16) -> float:
	return snapped((rotation + PI) / TAU * (frames), 1)

func is_owned_by_user() -> bool:
	if team_id == RTS.player.team_id:
		return true
	return false

func on_point_select(point:Vector2, list:Array[BaseUnit]):
	if dummy: return
	if dying: return
	
	if collision_shape.shape.get_rect().has_point(point - position):
		list.append(self)

func on_box_select(box:Rect2, list:Array[BaseUnit]):
	if dummy: return
	if !is_owned_by_user(): return
	if dying: return
	
	box.position -= position
	if collision_shape.shape.get_rect().intersection(box):
		list.append(self)

func waypoint(position:Vector2, clicked_unit:Node2D):
	if dummy: return
	if dying: return
	
	if Input.is_action_pressed("shift"):
		waypoints.append(position)
	else:
		waypoints = [position]

func on_body_enter_vision(body:Node2D):
	if body == self: return
	if body.is_in_group("unit") or body.is_in_group("building"):
		vision_list.append(body)

func on_body_exit_vision(body:Node2D):
	if vision_list.has(body):
		vision_list.remove_at(vision_list.find(body))

###################################################################################
# ATTACK / FIGHTING CODE
###################################################################################

func attack_ai():
	pass

func damage(_damage:int):
	health -= _damage

func kill():
	dying = true
	if selected: RTS.call_deferred("remove_selection", self, true)
	
	var sound_player := AudioStreamPlayer2D.new()
	sound_player.stream = Explosion_sound
	sound_player.autoplay = true
	sound_player.finished.connect(queue_free)
	add_child(sound_player)
	
	#var death_timer := Timer.new()
	#death_timer.autostart = true
	#death_timer.wait_time = 0.2
	#death_timer.timeout.connect(queue_free)
	#add_child(death_timer)
	
	var explosion = Sprite2D.new()
	explosion.texture = Explosion
	add_child(explosion)

"""
var peer_id:int
var path_list:Array[Vector2]
#var targets:Array[Node2D]
var in_vision:Array[Node2D]
var target:Node2D
var chase_target:Node2D
var chase_time:float
var custom_actions:Array[Callable]	
var default_actions := [
	attack_target
]

var health:float:
	get():
		return health
	set(value):
		health = value
		health_bar.value = health / base_health * 100
		#health_bar.value = 100

enum states {STANDBY, ATTACKING, ATTACK_CHASE, HOLD}
var cur_state:int = states.STANDBY

enum TAGS {NONE, NOAI, UNDETECTABLE, INVINCIBLE, UNSELECTABLE}
var tags:Array = [TAGS.NONE]

const MAX_CHASE_TIME := 4.0

func _ready() -> void:
	set_collision_layer_value(2, true)
	
	y_sort_enabled = true
	var uv := Unit_vision.instantiate()
	uv.name = "UnitAttack"
	add_child(uv)
	uv.get_child(0).shape = CircleShape2D.new()
	uv.get_child(0).shape.radius = detect_radius
	uv.set_collision_layer_value(1, false)
	uv.set_collision_mask_value(1, false)
	uv.set_collision_mask_value(2, true)
	detect = uv
	detect.body_entered.connect(on_body_entered)
	detect.body_exited.connect(on_body_exited)
	
	
	search_vision_timer = Timer.new()
	search_vision_timer.one_shot = false
	search_vision_timer.autostart = true
	search_vision_timer.wait_time = 1
	#search_vision_timer.timeout.connect(search_vision)
	add_child(search_vision_timer)
	
	chase_cooldown_timer = Timer.new()
	chase_cooldown_timer.one_shot = true
	chase_cooldown_timer.wait_time = 3
	add_child(chase_cooldown_timer)
	
	unit_vision = Unit_vision.instantiate()
	unit_vision.name = "UnitVision"
	unit_vision.set_collision_layer_value(1, false)
	unit_vision.set_collision_mask_value(1, false)
	unit_vision.set_collision_mask_value(2, true)
	add_child(unit_vision)
	unit_vision.get_child(0).shape = CircleShape2D.new()
	unit_vision.get_child(0).shape.radius = vision_radius
	#unit_vision.body_entered.connect(on_body_enter_vision)
	#unit_vision.body_exited.connect(on_body_exit_vision)
	
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
	#attack_ai()
	queue_redraw()

func on_right_click(pos:Vector2, clicked_obj:Node2D = null):
	if clicked_obj and !Input.is_action_pressed("shift"):
		target = clicked_obj
	else:
		target = null
		if Input.is_action_pressed("shift"):
			add_path_point(pos)
		else:
			add_path_point(pos, true)
	if Input.is_action_pressed("shift"):
		add_path_point(pos)
	else:
		add_path_point(pos, true)

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	
	movement(delta)
	move_and_slide()

func movement(delta:float):
	if tags.has(TAGS.NOAI): return
	
	if path_list:
		var dist_to_target:Vector2 = path_list[0] - position
		
		velocity += dist_to_target.normalized() * base_speed
		
		base_sprite.frame = get_sprite_frame_from_rotation(dist_to_target.angle() + PI)
		
		if dist_to_target.length_squared() <= 1000:
			path_list.remove_at(0)
		
	else:
		if chase_target:	# move towards chase target
			var dist_to_target:Vector2 = chase_target.position - position
			if dist_to_target.length() <= detect_radius or chase_time >= MAX_CHASE_TIME:
				chase_target = null
				chase_cooldown_timer.start()
				cur_state = states.STANDBY
				return
			chase_time += delta
			base_sprite.frame = get_sprite_frame_from_rotation(dist_to_target.angle() + PI)
			velocity += dist_to_target.normalized() * base_speed

func add_path_point(pos:Vector2, replace_list:bool = false):
	if replace_list:
		path_list = []
		path_list.append(pos)
	else:
		path_list.append(pos)



func on_body_enter_vision(body:Node2D):
	if tags.has(TAGS.NOAI): return
	
	if body.is_in_group("unit") or body.is_in_group("building"):
		if body.team_id != team_id:
			in_vision.append(body)

func on_body_exit_vision(body:Node2D):
	if tags.has(TAGS.NOAI): return
	
	if in_vision.has(body):
		in_vision.remove_at(in_vision.find(body))
	if chase_target == body:
		chase_target = null

func on_body_entered(body:Node2D):
	if tags.has(TAGS.NOAI): return
	
	if body.is_in_group("unit") or body.is_in_group("building"):
		if body.team_id != team_id:
			targets.append(body)
			if !target:
				target = body

func on_body_exited(body:Node2D):
	if tags.has(TAGS.NOAI): return
	
	if targets.has(body):
		targets.remove_at(targets.find(body))
		if target == body:
			if targets:
				target = targets[0]
			else:
				target = null

func attack_ai():
	
	if tags.has(TAGS.NOAI): return
	
	match cur_state:
		states.STANDBY:
			if target:
				cur_state = states.ATTACKING
		states.ATTACKING:
			if target:
				if position.distance_to(target.position) > detect_radius:
					chase_target = target
				elif attack_timer.is_stopped():
					attack_target()
					attack_timer.start()
			else:
				cur_state = states.STANDBY
		_:
			pass

func search_vision():
	if path_list: return
	
	if !chase_target and chase_cooldown_timer.is_stopped():
		for unit in in_vision:
			if (unit.position - position).length() <= agression_distance:
				if cur_state != states.ATTACKING or states.HOLD:
					cur_state = states.ATTACK_CHASE
					chase_target = unit
					chase_time = 0

var draw_attack := false
func attack_target():
	if tags.has(TAGS.NOAI): return
	
	target.on_attack(damage)
	chase_target = null
	draw_attack = true

func on_attack(damage:float):
	if tags.has(TAGS.INVINCIBLE): return
	cur_state = states.STANDBY
	chase_target = null
	health -= damage
	if health <= 0:
		killed()

func killed():
	if tags.has(TAGS.INVINCIBLE): return
	
	if is_in_group("selected_unit"):
		RTS.remove_from_select(self)
	queue_free()



func box_select(box: Rect2, epsteins_list: Array):
	if !is_owned_by_user(): return
	if tags.has(TAGS.UNSELECTABLE): return
	
	var self_box := Rect2(collision_shape.get_shape().get_rect().position + position, collision_shape.get_shape().get_rect().size)
	if box.intersects(self_box):
		epsteins_list.append(self)

func point_select(point: Vector2, list:Array):
	if tags.has(TAGS.UNSELECTABLE): return
	
	var self_box := Rect2(collision_shape.get_shape().get_rect().position + position, collision_shape.get_shape().get_rect().size)
	if self_box.has_point(point):
		list.append(self)

func get_sprite_frame_from_rotation(rotation:float, frames:int = 16) -> float:
	return snapped(rotation / TAU * (frames), 1)

func selected():
	if tags.has(TAGS.UNSELECTABLE): return
	
	health_bar.show()
	add_to_group("selected_unit")

func deselected():
	health_bar.hide()
	remove_from_group("selected_unit")

func _draw():
	if is_in_group("selected_unit"):
		# Draws the selected square
		if is_owned_by_user():
			draw_rect(collision_shape.get_shape().get_rect().grow(5), Color.GREEN, false, 2)
		else:
			draw_rect(collision_shape.get_shape().get_rect().grow(5), Color.RED, false, 2)
		
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
"""
