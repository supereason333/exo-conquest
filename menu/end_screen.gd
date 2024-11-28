extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label3.text = "Elapsed time: " + str(MultiplayerScript.game_end_time - MultiplayerScript.game_start_time)

func _on_button_pressed() -> void:
	MultiplayerScript.multiplayer_cleanup()
	get_tree().change_scene_to_file("res://menu/main_menus/title_screen.tscn")
