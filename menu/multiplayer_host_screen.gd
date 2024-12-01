extends Control

@onready var err_label := $MarginContainer/VBoxContainer/HBoxContainer/LeftBox/ServerInfo/MarginContainer/VBoxContainer/ErrorLabel
@onready var port_entry := $MarginContainer/VBoxContainer/HBoxContainer/LeftBox/ServerInfo/MarginContainer/VBoxContainer/PortEntry
@onready var spin_box := $MarginContainer/VBoxContainer/HBoxContainer/LeftBox/GameInfo/MarginContainer/VBoxContainer/HBoxContainer/SpinBox
@onready var window := $Window

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/main_menus/title_screen.tscn")


func _on_host_button_pressed() -> void:
	window.popup()
	
	return
	var err = MultiplayerScript.host_server(port_entry.text.to_int(), spin_box.value)
	if err:
		err_label.text = err
	else:
		get_tree().change_scene_to_file("res://menu/ready_screen.tscn")
	
