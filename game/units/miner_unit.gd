extends "res://game/units/base_unit/base_unit.gd"

var base_core:Node2D

func _ready() -> void:
	super()
	base_core = get_close_core()

func _process(delta: float) -> void:
	super(delta)

func _physics_process(delta: float) -> void:
	super(delta)

func _draw() -> void:
	super()
	if is_in_group("selected_unit"):
		if base_core:
			draw_line(Vector2.ZERO, base_core.position - position, Color.WHITE)

func search_vision():
	pass

func gather_resource():
	pass

func get_close_core() -> Node2D:
	if dummy: return
	
	var team_cores:Array[Node2D]
	for core in get_tree().get_nodes_in_group("core"):
		if core.team_id == team_id and core.is_in_group("core"):
			team_cores.append(core)
	
	var shortest_dist:float = INF
	var shortest_core:Node2D
	for core in team_cores:
		var dis := position.distance_squared_to(core.position)
		if dis < shortest_dist:
			shortest_dist = dis
			shortest_core = core
	
	print(shortest_core)
	return shortest_core
