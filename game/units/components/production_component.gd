extends Component
class_name ProductionComponent

signal produced_unit(unit:PackedScene)

@export var produce_list:Array[PackedScene]
@export var production_time:float = 10

var production_queue:Array[int]

const MAX_QUEUE_SIZE := 6

var timer:Timer = Timer.new()
@onready var game_enviroment := $"../.."
@onready var unit := $".." as BaseUnit

func _ready():
	timer.wait_time = production_time
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

func queue_unit(list_index: int):
	if unit.dummy: return
	if production_queue.size() < MAX_QUEUE_SIZE and list_index < produce_list.size():
		production_queue.append(list_index)
		if timer.is_stopped():
			timer.start()

func _on_timer_timeout() -> void:
	if production_queue:
		var last_produced = produce_list[production_queue[0]]
		production_queue.remove_at(0)
		produced_unit.emit(last_produced)
		if production_queue:
			timer.start()
			
