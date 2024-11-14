extends Control

@onready var port_entry := $MarginContainer/VBoxContainer/ManualType/MarginContainer/VBoxContainer/PortEntry
@onready var address_entry := $MarginContainer/VBoxContainer/ManualType/MarginContainer/VBoxContainer/AddressEntry

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/main_menus/title_screen.tscn")


func _on_join_button_pressed() -> void:
	var port:int = port_entry.text.to_int()
	
	MultiplayerScript.join_server(address_entry.text, port)
