extends Node

@onready var game_env := $".."

func _ready() -> void:
	RTS.select_list_changed.connect(select_list_changed)

func init():
	game_env.pre_game_init()
	game_env.player.set_dialogue("Incomming transmission:\n\nCommander, we have picked up unknown signals off planet N274. These signals could suggest other parties are at the location. Your mission is to explore the landscape and destroy the competition to give the company a lead in colonizing.")
	var core := BuildingLoader.load_building_from_id(1)
	core.position = Vector2(1000, 2530)
	core.team_id = 1
	game_env.add_building(core)

func select_list_changed():
	pass
