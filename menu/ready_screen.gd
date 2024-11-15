extends Control

@onready var ready_btn := $MarginContainer/HBoxContainer/LeftBox/HBoxContainer/ReadyButton
@onready var ready_color_rect := $MarginContainer/HBoxContainer/LeftBox/HBoxContainer/ColorRect
@onready var start_btn := $MarginContainer/HBoxContainer/LeftBox/StartButton

func _ready() -> void:
	if multiplayer.is_server(): start_btn.show()

func _on_start_button_pressed() -> void:
	if !multiplayer.is_server(): return
	if MultiplayerScript.check_can_start():
		MultiplayerScript.start_game()

func _on_ready_button_pressed() -> void:
	MultiplayerScript.ready_status = !MultiplayerScript.ready_status
	if MultiplayerScript.ready_status:
		ready_btn.text = "Unready"
		ready_color_rect.color = Color.GREEN
	else:
		ready_btn.text = "Ready!"
		ready_color_rect.color = Color.RED
