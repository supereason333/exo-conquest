extends CharacterBody2D
class_name BaseUnit

signal death(unit:Node2D)
signal taken_damage()
signal arrived
signal started_move

var peer_id:int
var waypoints:Array[Vector2]
var selected := false: set = set_selected
func set_selected(value):
	health_bar.visible = value
	selected = value
	queue_redraw()
var vision_list:Array[BaseUnit]
var attackable_list:Array[BaseUnit]
var dying := false
var override_target := false
var attacking := false
var moving := false:
	set(value):
		if value != moving:
			if value: emit_signal("started_move")
			else: emit_signal("arrived")
			moving = value
var attack_target:Node2D:
	set(value):
		if attack_target:
			attack_target.death.disconnect(target_death)
		if value:
			value.death.connect(target_death)
		
		attack_target = value
var chase_target:BaseUnit
var rand := RandomNumberGenerator.new()
var last_pos:Vector2
var frames_stuck:int

@export var unit_name:String
@export var unit_id:int
@export var unit_cost:MaterialCost
@export var team_id:int:
	set(value):
		var team := MultiplayerScript.get_team_from_id(team_id)
		if team:
			if unit_sprite:
				unit_sprite.color = team.color
		team_id = value

@export_group("Movement")
@export var base_speed:int
@export var stuck_threshold:float = 0.2

@export_group("Attack")
@export var base_health:float
@export var attack_damage:float
@export var attack_cooldown:float
@export var attack_range:int
@export var vision_radius:int
@export var agression_distance:int
@export var chase_time:float = 4
@export var chase_cooldown:float = 4

@export_group("Sprite")
@export var unit_sprite:UnitSprite
@export var display_icon:CompressedTexture2D = preload("res://game/resources/sprites/placeholder/32x.png")
@export var attack_animation_time:float = 0.2
@export var death_sound := AudioManager.SFX.Unit.Death.explosion
@export var death_effect := preload("res://game/units/base_unit/death_effects/default_effect.tscn")
@export var attack_sound := AudioManager.SFX.Unit.Attack.gunshot

@export_group("Components")
#@export var base_sprite:AnimatedSprite2D
#@export var color_sprite:AnimatedSprite2D
@export var collision_shape:CollisionShape2D
@export var production_component:ProductionComponent
@export var multiplayer_sync:MultiplayerSynchronizer
@export var other_components:Array[Component]

@export_group("Other") 
@export var dummy:bool = false
@export var frozen:bool = false:
	set(value):
		frozen = value
		if frozen:
			waypoints = []

var health:float:
	get():
		return health
	set(value):
		emit_signal("taken_damage")
		health = value
		health_bar.value = health / base_health * 100
		
		if value <= 0:
			kill()

@onready var game_env := $".."
var vision_area:Area2D = Area2D.new()
var attack_area:Area2D = Area2D.new()
var health_bar:ProgressBar = ProgressBar.new()
var attack_timer:Timer = Timer.new()
var attack_tick_timer:Timer = Timer.new()
var attack_anim_timer:Timer = Timer.new()
var chase_timer:Timer = Timer.new()
var chase_cooldown_timer:Timer = Timer.new()
var idle_anim_timer:Timer = Timer.new()
#var unit_finder_timer:Timer = Timer.new()
var sound_player:AudioStreamPlayer2D = AudioStreamPlayer2D.new()

enum states {STANDBY, ATTACKING, ATTACK_CHASE, HOLD}
var cur_state:int = states.STANDBY

func _ready() -> void:
	#if base_sprite:
	#	base_sprite.frame_changed.connect(sprite_frame_changed)
	started_move.connect(_on_started_move)
	arrived.connect(_on_arrived)
	
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
	
	set_team(team_id)
	
	if production_component:
		production_component._produced_unit.connect(unit_produced)
	
	if !is_multiplayer_authority(): 
		return
	
	RTS.core_death.connect(core_death)
	
	chase_timer.one_shot = true
	chase_timer.wait_time = chase_time
	chase_timer.autostart = false
	chase_timer.timeout.connect(chase_timer_timeout)
	add_child(chase_timer)
	chase_cooldown_timer.wait_time = chase_cooldown
	chase_cooldown_timer.one_shot = true
	chase_cooldown_timer.autostart = false
	add_child(chase_cooldown_timer)
	idle_anim_timer.one_shot = true
	idle_anim_timer.autostart = false
	add_child(idle_anim_timer)
	
	if dummy: 
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		return
	
	if !collision_shape:
		pass
	
	set_collision_layer_value(2, true)
	add_to_group("unit")
	
	sound_player.stream = attack_sound
	sound_player.autoplay = false
	sound_player.bus = "SFX"
	add_child(sound_player)
	
	var vision_area_shape := CollisionShape2D.new()
	vision_area_shape.shape = CircleShape2D.new()
	vision_area_shape.shape.radius = vision_radius
	vision_area.add_child(vision_area_shape)
	vision_area.set_collision_mask_value(1, false)
	vision_area.set_collision_layer_value(1, false)
	vision_area.set_collision_mask_value(2, true)
	vision_area.body_entered.connect(on_body_enter_vision)
	vision_area.body_exited.connect(on_body_exit_vision)
	add_child(vision_area)
	
	var attack_area_shape := CollisionShape2D.new()
	attack_area_shape.shape = CircleShape2D.new()
	attack_area_shape.shape.radius = attack_range
	attack_area.add_child(attack_area_shape)
	attack_area.set_collision_mask_value(1, false)
	attack_area.set_collision_layer_value(1, false)
	attack_area.set_collision_mask_value(2, true)
	#attack_area.set_collision_mask_value(2, false)
	attack_area.body_entered.connect(on_body_enter_attack)
	attack_area.body_exited.connect(on_body_exit_attack)
	add_child(attack_area)
	
	if attack_cooldown != 0:
		attack_timer.wait_time = attack_cooldown
		attack_timer.one_shot = true
		attack_timer.timeout.connect(attack_ai)
		add_child(attack_timer)
	
	attack_tick_timer.wait_time = 0.05
	attack_tick_timer.autostart = false
	attack_tick_timer.timeout.connect(attack_tick)
	add_child(attack_tick_timer)
	
	if attack_animation_time != 0:
		attack_anim_timer.wait_time = attack_animation_time
		attack_anim_timer.autostart = false
		attack_anim_timer.timeout.connect(attack_end)
		add_child(attack_anim_timer)
	
	#unit_finder_timer.wait_time = 1
	#unit_finder_timer.autostart = false
	#unit_finder_timer.timeout.connect(target_search)
	#add_child(unit_finder_timer)
	

func _process(_delta: float) -> void:
	if dummy: return
	if dying: return
	
	if Input.is_action_just_pressed("get_data"):
		if selected:
			print("UNIT")
			print(vision_list)
			print(attackable_list)
			print(attack_target)
	

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

func unit_produced(_unit:PackedScene):
	var unit := _unit.instantiate()
	unit.team_id = RTS.player.team_id
	unit.position = position + Vector2(0, 100)
	unit.waypoints.append(position + Vector2(200, 0))
	game_env.add_unit(unit)

func movement(_delta:float):
	if frozen: return
	if !is_multiplayer_authority(): return
	
	if chase_target and !attacking and !waypoints:
		if !is_instance_valid(chase_target):
			chase_target = null
			moving = false
			return
		if position.distance_squared_to(chase_target.position) <= pow(attack_range, 2) * 0.7:
			chase_target = null
			moving = false
			return
		moving = true
		velocity = Vector2.ZERO
		var direction := position.direction_to(chase_target.position).normalized()
		velocity += direction * base_speed
		#base_sprite.frame = get_sprite_frame_from_rotation(direction.angle())
		#set_sprite_rotation(direction.angle())
		unit_sprite.set_visual_rotation(direction.angle())
		move_and_slide()
		return
	elif waypoints and !attacking:
		if position.distance_squared_to(waypoints[0]) <= 100:
			waypoints.remove_at(0)
			if !waypoints: 
				moving = false
				return
		moving = true
		velocity = Vector2.ZERO
		var direction := (waypoints[0] - position).normalized()
		velocity += direction * base_speed
		#base_sprite.frame = get_sprite_frame_from_rotation(direction.angle())
		#set_sprite_rotation(direction.angle())
		unit_sprite.set_visual_rotation(direction.angle())
		move_and_slide()
		if position.distance_squared_to(last_pos) <= stuck_threshold and waypoints:
			
			frames_stuck += 1
			if frames_stuck >= 5:
				waypoints = []
				frames_stuck = 0
		else:
			frames_stuck = 0
		last_pos = position
		return
	moving = false
	if idle_anim_timer.is_stopped():
		idle_anim_timer.wait_time = rand.randf_range(2, 10)
		idle_anim_timer.start()
		if rand.randf() <= 0.5:
			var num = rand.randi_range(1, 2)
			if unit_sprite.frame_coords.y + num >= unit_sprite.vframes:
				unit_sprite.frame_coords.y = num
			else:
				unit_sprite.frame_coords.y += 1
		else:
			var num = rand.randi_range(1, 2)
			if unit_sprite.frame_coords.y - num < 0:
				unit_sprite.frame_coords.y = unit_sprite.vframes - 1 - num
			else:
				unit_sprite.frame_coords.y -= 1

func set_team(_team_id:int):
	if dummy: return
	if dying: return
	
	team_id = _team_id

func get_sprite_frame_from_rotation(_rotation:float, frames:int = 16) -> float:
	return snapped((_rotation + PI) / TAU * (frames), 1)

#func set_sprite_rotation(rotation:float):
	#if rotation_per_frame:
		#base_sprite.frame = get_sprite_frame_from_rotation(rotation)
		#return
	#
	#base_sprite.play(str(get_sprite_frame_from_rotation(rotation)) + "_run")

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

@rpc("any_peer")
func waypoint(_position:Vector2, clicked_unit:Node2D, hold:bool):
	if frozen: return
	if dummy: return
	if dying: return
	if !is_multiplayer_authority(): 
		rpc_id(1, "waypoint", _position, null, Input.is_action_pressed("shift"))
		return
	
	chase_target = null
#	if !waypoints:
#		emit_signal("started_move")
	if clicked_unit:
		pass
	if hold:
		waypoints.append(_position)
	else:
		waypoints = [_position]

func on_body_enter_vision(body:Node2D):
	#if !is_multiplayer_authority(): return
	if body == self: return
	if body is BaseUnit: #body.is_in_group("unit") or body.is_in_group("building"):
		if body.team_id != team_id: 
			vision_list.append(body)
			#enable_attack_area()
			if attack_tick_timer.is_stopped(): 
				attack_tick_timer.start()

func on_body_exit_vision(body:Node2D):
	#if !is_multiplayer_authority(): return
	if vision_list.has(body):
		vision_list.remove_at(vision_list.find(body))
		if !vision_list:
			attack_tick_timer.stop()
			#disable_attack_area()
	if body == attack_target: attack_target = null

func on_body_enter_attack(body:Node2D):
	#if !is_multiplayer_authority(): return
	if vision_list.has(body):
		attackable_list.append(body)

func on_body_exit_attack(body:Node2D):
	#if !is_multiplayer_authority(): return
	if attackable_list.has(body):
		attackable_list.remove_at(attackable_list.find(body))
		if attack_target == body and !override_target:
			attack_timer.stop()
			attack_target = null

###################################################################################
# ATTACK / FIGHTING CODE
###################################################################################

func attack_ai():
	if dying: return
	if !is_multiplayer_authority(): return
	
	if attack_target:
		attack_start()
	else:
		print_debug("ATTACKED NULL")
		if !attack_timer.is_stopped(): attack_timer.stop()

func attack_start():
	attacking = true
	attack_animation()
	attack_target.damage(attack_damage)

func attack_end():
	if moving:
		emit_signal("started_move")
	attacking = false

func attack_animation():
	sound_player.play()
	unit_sprite.set_visual_rotation(position.angle_to_point(attack_target.position))
	unit_sprite.play_anim("attack")
	#base_sprite.frame = get_sprite_frame_from_rotation(position.direction_to(attack_target.position).angle())
	attack_anim_timer.start()

func attack_tick():
	# Only runs of something inside vision
	if dying: return
	if !is_multiplayer_authority(): return
	
	if !attack_target:
		#var bodies = attack_area.get_overlapping_bodies()
		if attackable_list:
			attack_target = attackable_list[0]
		elif !chase_target and chase_cooldown_timer.is_stopped():
			var _unit := find_target_within()
			if _unit:
				chase_target = _unit
				if chase_timer.is_stopped():
					chase_timer.start()
	else:
		if attack_timer.is_stopped():
			attack_timer.start()
			#attack_ai()

func chase_timer_timeout():
	chase_target = null
	if chase_cooldown_timer.is_stopped():
		chase_cooldown_timer.start()


#func target_search():
#	#print("Target search")
#	if !attack_target:
#		var target = find_target()
#		if target: 
#			#print("Found target")
#			attack_target = target
#			unit_finder_timer.stop()

func find_target_within(dist:float = -1) -> BaseUnit:
	if !vision_list: return null
	if dist == -1: dist = agression_distance
	
	for unit in vision_list:
		if position.distance_to(unit.position) <= dist:
			return unit
	
	return null

func find_target(in_attack_distance:bool = true) -> BaseUnit:
	if !vision_list: return null
	
	var closest_dist:float = INF
	var closest_unit:BaseUnit
	for unit in vision_list:
		var dist = position.distance_squared_to(unit.position)
		if dist < closest_dist:
			closest_dist = dist
			closest_unit = unit
	
	if in_attack_distance:
		if closest_dist <= pow(attack_range, 2):
			return closest_unit
		else:
			return null
	else:
		return closest_unit

func target_in_range() -> bool:
	if position.distance_squared_to(attack_target.position) <= pow(attack_range, 2): return true
	else: return false

func target_death(unit:Node2D):
	attack_target = null
	if vision_list.has(unit):
		vision_list.remove_at(vision_list.find(unit))
		#attackable_list.remove_at(attackable_list.find(unit))
	attack_timer.stop()

func damage(_damage:int):
	health -= _damage
	if health <= 0:
		kill()

#@rpc("any_peer")
func kill():
	if dying: return
	
	if health != 0:
		health = 0
	
	#if !multiplayer.is_server():
		#rpc_id(1, "kill")
	
	emit_signal("death", self)
	print(str(multiplayer.get_unique_id()))
	if selected: RTS.call_deferred("remove_selection", self, true)
	dying = true
	
	var death_sound_player := AudioStreamPlayer2D.new()
	death_sound_player.stream = death_sound
	death_sound_player.finished.connect(queue_free)
	add_child(death_sound_player)
	death_sound_player.play()
	
	var _death_effect := death_effect.instantiate()
	add_child(_death_effect)
	
	collision_shape.queue_free()
	
	vision_area.queue_free()
	attack_area.queue_free()
	

@rpc("any_peer")
func despawn():
	if !is_multiplayer_authority():
		rpc("despawn")
		queue_free()
		return
	
	queue_free()

func _on_started_move() -> void:
	unit_sprite.play_anim("walk")

func _on_arrived() -> void:
	unit_sprite.play_anim("idle")

func core_death():
	waypoints = []

#var peer_id:int
#var path_list:Array[Vector2]
##var targets:Array[Node2D]
#var in_vision:Array[Node2D]
#var target:Node2D
#var chase_target:Node2D
#var chase_time:float
#var custom_actions:Array[Callable]	
#var default_actions := [
	#attack_target
#]
#
#var health:float:
	#get():
		#return health
	#set(value):
		#health = value
		#health_bar.value = health / base_health * 100
		##health_bar.value = 100
#
#enum states {STANDBY, ATTACKING, ATTACK_CHASE, HOLD}
#var cur_state:int = states.STANDBY
#
#enum TAGS {NONE, NOAI, UNDETECTABLE, INVINCIBLE, UNSELECTABLE}
#var tags:Array = [TAGS.NONE]
#
#const MAX_CHASE_TIME := 4.0
#
#func _ready() -> void:
	#set_collision_layer_value(2, true)
	#
	#y_sort_enabled = true
	#var uv := Unit_vision.instantiate()
	#uv.name = "UnitAttack"
	#add_child(uv)
	#uv.get_child(0).shape = CircleShape2D.new()
	#uv.get_child(0).shape.radius = detect_radius
	#uv.set_collision_layer_value(1, false)
	#uv.set_collision_mask_value(1, false)
	#uv.set_collision_mask_value(2, true)
	#detect = uv
	#detect.body_entered.connect(on_body_entered)
	#detect.body_exited.connect(on_body_exited)
	#
	#
	#search_vision_timer = Timer.new()
	#search_vision_timer.one_shot = false
	#search_vision_timer.autostart = true
	#search_vision_timer.wait_time = 1
	##search_vision_timer.timeout.connect(search_vision)
	#add_child(search_vision_timer)
	#
	#chase_cooldown_timer = Timer.new()
	#chase_cooldown_timer.one_shot = true
	#chase_cooldown_timer.wait_time = 3
	#add_child(chase_cooldown_timer)
	#
	#unit_vision = Unit_vision.instantiate()
	#unit_vision.name = "UnitVision"
	#unit_vision.set_collision_layer_value(1, false)
	#unit_vision.set_collision_mask_value(1, false)
	#unit_vision.set_collision_mask_value(2, true)
	#add_child(unit_vision)
	#unit_vision.get_child(0).shape = CircleShape2D.new()
	#unit_vision.get_child(0).shape.radius = vision_radius
	##unit_vision.body_entered.connect(on_body_enter_vision)
	##unit_vision.body_exited.connect(on_body_exit_vision)
	#
	#attack_timer = Timer.new()
	#attack_timer.wait_time = attack_cooldown
	#attack_timer.one_shot = true
	#add_child(attack_timer)
	#
	#health_bar = ProgressBar.new()
	#health_bar.name = "HealthBar"
	#health_bar.show_percentage = false
	#health_bar.size = Vector2(50, 6)
	#health_bar.position = Vector2(-health_bar.size.x / 2, collision_shape.shape.size.y / 2 + 10)
	#var style_box = StyleBoxFlat.new()
	#style_box.bg_color = Color.RED
	#health_bar.add_theme_stylebox_override("background", style_box)
	#style_box = StyleBoxFlat.new()
	#style_box.bg_color = Color.GREEN
	#health_bar.add_theme_stylebox_override("fill", style_box)
	#health_bar.visible = false
	#health = base_health
	#add_child(health_bar)
	#
	#var team := MultiplayerScript.get_team_from_id(team_id)
	#if team:
		#base_sprite.color = team.color
#
#func _process(delta: float) -> void:
	##attack_ai()
	#queue_redraw()
#
#func on_right_click(pos:Vector2, clicked_obj:Node2D = null):
	#if clicked_obj and !Input.is_action_pressed("shift"):
		#target = clicked_obj
	#else:
		#target = null
		#if Input.is_action_pressed("shift"):
			#add_path_point(pos)
		#else:
			#add_path_point(pos, true)
	#if Input.is_action_pressed("shift"):
		#add_path_point(pos)
	#else:
		#add_path_point(pos, true)
#
#func _physics_process(delta: float) -> void:
	#velocity = Vector2.ZERO
	#
	#movement(delta)
	#move_and_slide()
#
#func movement(delta:float):
	#if tags.has(TAGS.NOAI): return
	#
	#if path_list:
		#var dist_to_target:Vector2 = path_list[0] - position
		#
		#velocity += dist_to_target.normalized() * base_speed
		#
		#base_sprite.frame = get_sprite_frame_from_rotation(dist_to_target.angle() + PI)
		#
		#if dist_to_target.length_squared() <= 1000:
			#path_list.remove_at(0)
		#
	#else:
		#if chase_target:	# move towards chase target
			#var dist_to_target:Vector2 = chase_target.position - position
			#if dist_to_target.length() <= detect_radius or chase_time >= MAX_CHASE_TIME:
				#chase_target = null
				#chase_cooldown_timer.start()
				#cur_state = states.STANDBY
				#return
			#chase_time += delta
			#base_sprite.frame = get_sprite_frame_from_rotation(dist_to_target.angle() + PI)
			#velocity += dist_to_target.normalized() * base_speed
#
#func add_path_point(pos:Vector2, replace_list:bool = false):
	#if replace_list:
		#path_list = []
		#path_list.append(pos)
	#else:
		#path_list.append(pos)
#
#
#
#func on_body_enter_vision(body:Node2D):
	#if tags.has(TAGS.NOAI): return
	#
	#if body.is_in_group("unit") or body.is_in_group("building"):
		#if body.team_id != team_id:
			#in_vision.append(body)
#
#func on_body_exit_vision(body:Node2D):
	#if tags.has(TAGS.NOAI): return
	#
	#if in_vision.has(body):
		#in_vision.remove_at(in_vision.find(body))
	#if chase_target == body:
		#chase_target = null
#
#func on_body_entered(body:Node2D):
	#if tags.has(TAGS.NOAI): return
	#
	#if body.is_in_group("unit") or body.is_in_group("building"):
		#if body.team_id != team_id:
			#targets.append(body)
			#if !target:
				#target = body
#
#func on_body_exited(body:Node2D):
	#if tags.has(TAGS.NOAI): return
	#
	#if targets.has(body):
		#targets.remove_at(targets.find(body))
		#if target == body:
			#if targets:
				#target = targets[0]
			#else:
				#target = null
#
#func attack_ai():
	#
	#if tags.has(TAGS.NOAI): return
	#
	#match cur_state:
		#states.STANDBY:
			#if target:
				#cur_state = states.ATTACKING
		#states.ATTACKING:
			#if target:
				#if position.distance_to(target.position) > detect_radius:
					#chase_target = target
				#elif attack_timer.is_stopped():
					#attack_target()
					#attack_timer.start()
			#else:
				#cur_state = states.STANDBY
		#_:
			#pass
#
#func search_vision():
	#if path_list: return
	#
	#if !chase_target and chase_cooldown_timer.is_stopped():
		#for unit in in_vision:
			#if (unit.position - position).length() <= agression_distance:
				#if cur_state != states.ATTACKING or states.HOLD:
					#cur_state = states.ATTACK_CHASE
					#chase_target = unit
					#chase_time = 0
#
#var draw_attack := false
#func attack_target():
	#if tags.has(TAGS.NOAI): return
	#
	#target.on_attack(damage)
	#chase_target = null
	#draw_attack = true
#
#func on_attack(damage:float):
	#if tags.has(TAGS.INVINCIBLE): return
	#cur_state = states.STANDBY
	#chase_target = null
	#health -= damage
	#if health <= 0:
		#killed()
#
#func killed():
	#if tags.has(TAGS.INVINCIBLE): return
	#
	#if is_in_group("selected_unit"):
		#RTS.remove_from_select(self)
	#queue_free()
#
#
#
#func box_select(box: Rect2, epsteins_list: Array):
	#if !is_owned_by_user(): return
	#if tags.has(TAGS.UNSELECTABLE): return
	#
	#var self_box := Rect2(collision_shape.get_shape().get_rect().position + position, collision_shape.get_shape().get_rect().size)
	#if box.intersects(self_box):
		#epsteins_list.append(self)
#
#func point_select(point: Vector2, list:Array):
	#if tags.has(TAGS.UNSELECTABLE): return
	#
	#var self_box := Rect2(collision_shape.get_shape().get_rect().position + position, collision_shape.get_shape().get_rect().size)
	#if self_box.has_point(point):
		#list.append(self)
#
#func get_sprite_frame_from_rotation(rotation:float, frames:int = 16) -> float:
	#return snapped(rotation / TAU * (frames), 1)
#
#func selected():
	#if tags.has(TAGS.UNSELECTABLE): return
	#
	#health_bar.show()
	#add_to_group("selected_unit")
#
#func deselected():
	#health_bar.hide()
	#remove_from_group("selected_unit")
#
#func _draw():
	#if is_in_group("selected_unit"):
		## Draws the selected square
		#if is_owned_by_user():
			#draw_rect(collision_shape.get_shape().get_rect().grow(5), Color.GREEN, false, 2)
		#else:
			#draw_rect(collision_shape.get_shape().get_rect().grow(5), Color.RED, false, 2)
		#
		## Draws the path
		#for i in len(path_list):
			#if i >= 1:
				#draw_line(path_list[i - 1] - position, path_list[i] - position, Color.GRAY, 1)
			#else:
				#draw_line(Vector2.ZERO, path_list[0] - position, Color.GRAY, 1)
			#draw_circle(path_list[i] - position, 10, Color.GRAY, false, 1)
	#
	#if draw_attack:
		#if target:
			#draw_line(Vector2.ZERO, target.position - position, MultiplayerScript.get_team_from_id(team_id).color, 1)
			#draw_attack = false
#
#func is_owned_by_user() -> bool:
	#if team_id == RTS.player.team_id:
		#return true
	#return false


# alpha release when?
