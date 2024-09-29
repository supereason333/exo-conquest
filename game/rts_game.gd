extends Node

signal select_list_changed

signal point_select(point:Vector2)
signal box_select(box:Rect2)

@export var player:PlayerData

# Materials
@export var material_list:Array[int]

var deselect_queue:Array
var called_deselect := false
var selected_list:Array
const MAX_SELECT_AMOUNT := 2

func _ready() -> void:
	set_default_player()

func _process(delta: float) -> void:
	pass
	#print(selected_list)

func set_default_player():
	player = PlayerData.new()
	player.peer_id = 1
	player.team_id = 0
	player.username = "DEFAULT PLAYER"

func add_to_select(troop, add:bool = true):
	if add:
		selected_list.append(troop)
	else:
		selected_list = [troop]
