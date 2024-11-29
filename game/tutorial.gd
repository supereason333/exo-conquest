extends Node

@onready var game_env := $".."

var camera_has_moved := false

func _ready() -> void:
	RTS.select_list_changed.connect(select_list_changed)
	$"../PlayerControl".building_placer_showen.connect(building_placer_showen)
	

func init():
	game_env.pre_game_init()
	game_env.player.set_dialogue("Incomming transmission:\n\nCommander, we have picked up unknown signals off planet N274. These signals could suggest other parties are at the location. Your mission is to explore the landscape and destroy the competition to give the company a lead in colonizing.")
	game_env.player.queue_dialogue("Click or drag to select units")
	game_env.player.queue_dialogue("Right click to direct units")
	game_env.player.queue_dialogue("WASD or move mouse to screen edge to move camera")
	game_env.player.queue_dialogue("Make more miners and use the building placer at bottom right of screen to place a building")
	var core := BuildingLoader.load_building_from_id(1)
	core.position = Vector2(1000, 2530)
	core.death.connect(on_core_death)
	core.team_id = 1
	game_env.add_building(core)

func select_list_changed():
	pass

func on_core_death(unit:BaseUnit):
	MultiplayerScript.game_winner = 1
	MultiplayerScript.end_game()

func building_placer_showen():
	pass

#func _on_incompetency_timer_timeout() -> void:
	#if !camera_has_moved:
		#game_env.player.set_dialogue("Use \"WASD\" or moved mouse to edge of screen to move camera")
