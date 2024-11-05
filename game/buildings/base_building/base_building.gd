extends StaticBody2D
class_name BaseBuilding

@export var size:Vector2i	# Size of the building in tiles
@export var base_health:float
@export var building_id:int
@export var building_name:String

@export_group("Costs")
@export var cost_selnite:int
@export var cost_luminite:int
@export var cost_plainium:int
@export var cost_xenite:int

@export_group("Other")
@export var dummy := false

var collision_shape:CollisionShape2D
var health_bar := ProgressBar.new()

var map_position:Vector2i
var team_id:float
var health := base_health:
	get():
		return health
	set(value):
		health = value
		health_bar.value = health / base_health * 100
		#health_bar.value = 100

@onready var building_sprite := $BaseBuildingSprite

func _ready() -> void:
	if dummy:
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
	
	add_to_group("building")
	set_collision_layer_value(2, true)
	y_sort_enabled = true
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = RectangleShape2D.new()
	collision_shape.shape.size = size * 32	# Times tile size
	add_child(collision_shape)
	
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
	building_sprite.team_color = team.color

func _process(delta: float) -> void:
	queue_redraw()

func set_map_position(pos:Vector2i):	# Sets the position of the building relatively to the map
	map_position = pos
	position = pos * 32

func point_select(pos:Vector2, list:Array):
	if collision_shape.shape.get_rect().has_point(pos - position):
		list.append(self)

func selected():
	#if !is_owned_by_user(): return
	health_bar.show()
	add_to_group("selected_building")

func deselected():
	health_bar.hide()
	remove_from_group("selected_building")

func _draw() -> void:
	if is_in_group("selected_building"):
		if team_id == RTS.player.team_id:
			draw_rect(collision_shape.shape.get_rect(), Color.GREEN, false, 2)
		else:
			draw_rect(collision_shape.shape.get_rect(), Color.RED, false, 2)

func on_attack(damage:float):
	health -= damage
	if health <= 0:
		killed()

func killed():
	if is_in_group("selected_building"):
		if RTS.selected_building == self:
			RTS.selected_building = null
	queue_free()
