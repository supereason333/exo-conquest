extends Component
class_name ProductionComponent

@export var produce_list:Array[PackedScene]
@export var production_time:float

var production_queue:Array[int]

const MAX_QUEUE_SIZE := 6

func queue_unit(list_index: int):
	pass
