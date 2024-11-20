extends BaseUnit

@onready var gather_timer := $GatherTimer
@onready var label := $GatheringLabel
var base_core:BaseBuilding

var gathering := false:
	set(value):
		if value:
			if gather_timer:
				if gather_timer.is_stopped():
					gather_timer.start()
			if label:
				if selected and target_material >= 0:
					label.show()
				else:
					label.hide()
		else:
			if gather_timer:
				gather_timer.stop()
			if label:
				label.hide()
		
		queue_redraw()
		gathering = value
var target_material := -1

const GATHER_AMOUNT := 2

func _ready() -> void:
	super()
	base_core = get_close_core()

func _process(delta: float) -> void:
	super(delta)
	if selected:
		queue_redraw()

func _physics_process(delta: float) -> void:
	super(delta)

func _draw() -> void:
	super()
	if selected:
		if base_core:
			draw_line(Vector2.ZERO, base_core.position - position, Color.WHITE)
		if gathering:
			pass

func movement(delta:float):
	super(delta)
	gathering = !moving

func set_selected(value):
	super(value)
	if value and gathering and target_material >= 0:
		label.show()
	else:
		label.hide()

func search_vision():
	pass

func gather_resource():
	
	match target_material:
		0:
			RTS.materials = RTS.materials.add(MaterialCost.new(GATHER_AMOUNT, 0 ,0 ,0))
		1:
			RTS.materials = RTS.materials.add(MaterialCost.new(0, GATHER_AMOUNT, 0, 0))
		2:
			RTS.materials = RTS.materials.add(MaterialCost.new(0, 0, GATHER_AMOUNT, 0))
		3:
			RTS.materials = RTS.materials.add(MaterialCost.new(0, 0, 0, GATHER_AMOUNT))
		_:
			pass
	

func waypoint(_position:Vector2, clicked_unit:Node2D, hold:bool):
	super(_position, clicked_unit, false)
	gathering = false
	
	var tile = game_env.data_tile_map.get_cell_tile_data(game_env.data_tile_map.local_to_map(_position))
	if tile:
		target_material = tile.get_custom_data("Material ID")
	else:
		target_material = -1

func get_close_core() -> BaseBuilding:
	if dummy: return
	
	var team_cores:Array[BaseBuilding]
	for core in get_tree().get_nodes_in_group("core"):
		if core.team_id == team_id and core.is_in_group("core"):
			team_cores.append(core)
	
	var shortest_dist:float = INF
	var shortest_core:BaseBuilding
	for core in team_cores:
		var dis := position.distance_squared_to(core.position)
		if dis < shortest_dist:
			shortest_dist = dis
			shortest_core = core
	
	print(shortest_core)
	return shortest_core
