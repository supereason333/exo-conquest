extends Control

@onready var err_label := $MarginContainer/VBoxContainer/HBoxContainer/LeftBox/ServerInfo/MarginContainer/VBoxContainer/ErrorLabel
@onready var port_entry := $MarginContainer/VBoxContainer/HBoxContainer/LeftBox/ServerInfo/MarginContainer/VBoxContainer/PortEntry

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/main_menus/title_screen.tscn")


func _on_host_button_pressed() -> void:
	var err = MultiplayerScript.host_server(port_entry.text.to_int())
	if err:
		err_label.text = err
	else:
		get_tree().change_scene_to_file("res://menu/ready_screen.tscn")
	
