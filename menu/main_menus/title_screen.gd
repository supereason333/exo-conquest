extends Control

func _on_exit_button_pressed():
	get_tree().quit()

func _on_singleplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/multiplayer_host_screen.tscn")

func _on_multiplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/main_menus/multiplayer_join_screen.tscn")

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/settings/settings.tscn")

func _on_tutorial_button_pressed() -> void:
	MultiplayerScript.host_server()
	MultiplayerScript.new_team("Enemy", "Erm, what the sigma?", Color.RED, 1)
	MultiplayerScript.new_team("Player", "Erm, what the sigma?", Color.LIGHT_PINK, 2)
	MultiplayerScript.game_start_time = Time.get_unix_time_from_system()
	RTS.player.team_id = 2
	RTS.start_position = 1
	get_tree().change_scene_to_file("res://game/tutorial_land.tscn")
