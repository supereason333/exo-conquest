extends Control

@onready var ready_btn := $MarginContainer/HBoxContainer/LeftBox/HBoxContainer/ReadyButton
@onready var ready_color_rect := $MarginContainer/HBoxContainer/LeftBox/HBoxContainer/ColorRect

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://game/game_environment.tscn")

func _on_ready_button_pressed() -> void:
	MultiplayerScript.ready_status = !MultiplayerScript.ready_status
	if MultiplayerScript.ready_status:
		ready_btn.text = "Unready"
		ready_color_rect.color = Color.GREEN
	else:
		ready_btn.text = "Ready!"
		ready_color_rect.color = Color.RED
