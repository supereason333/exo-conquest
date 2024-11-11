extends BaseBuilding

const PRODUCTION_TIME := 10.0
const MAX_QUEUE_SIZE := 6

var production_cost:Array[Array] = [
	[30, 0, 0, 0],	# Marine
	[30, 10, 0, 0]	# Sniper
]

var production_list:Array[int] = [
	5,	# Marine
	3	# Sniper
]
var production_queue:Array[int]

var production_timer:Timer = Timer.new()
@onready var game_env := $".."
@onready var queue_display := $VBoxContainer/QueueDisplay
@onready var progress_bar := $VBoxContainer/ProgressBar
@onready var control_node := $VBoxContainer

func _ready() -> void:
	super()
	
	base_sprite.play("flash")
	actions.append(queue_unit)
	
	production_timer.wait_time = PRODUCTION_TIME
	production_timer.autostart = false
	production_timer.one_shot = true
	production_timer.timeout.connect(production_finished)
	add_child(production_timer)
	
	progress_bar.max_value = PRODUCTION_TIME
	
	queue_unit(5)
	queue_unit(5)
	queue_unit(3)

func _process(delta: float) -> void:
	super(delta)
	
	if selected:
		if !production_timer.is_stopped():
			progress_bar.value = production_timer.time_left

func set_selected(value):
	super(value)
	
	control_node.visible = value
	if !value:
		for child in queue_display.get_children(): child.queue_free()
	else:
		update_queue_display()

func update_queue_display():
	for child in queue_display.get_children(): child.queue_free()
	
	for i in production_queue:
		var texture_rect: = TextureRect.new()
		#texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.texture = UnitLoader.load_unit_from_id(i).display_icon
		queue_display.add_child(texture_rect)

func queue_unit(unit:int):
	if dummy: return
	
	if production_list.has(unit) and production_queue.size() < MAX_QUEUE_SIZE: 
		production_queue.append(unit)
		
		if production_list:
			if production_timer.is_stopped():
				production_timer.start()

func production_finished():
	if dummy: return
	if production_queue:
		var unit = UnitLoader.load_unit_from_id(production_queue[0])
		production_queue.remove_at(0)
		if unit:
			unit.position = position + Vector2(0, 64)
			unit.waypoints.append(Vector2(64, 64) + position)
			unit.waypoints.append(Vector2(64, -64) + position)
			unit.waypoints.append(Vector2(-64, -64) + position)
			unit.waypoints.append(Vector2(-64, 64) + position)
			game_env.add_unit(unit)
		
		if production_queue:
			production_timer.start()
	
	update_queue_display()
