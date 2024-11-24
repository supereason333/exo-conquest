extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().create_timer(5).timeout.connect(_on_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/main_menus/title_screen.tscn")
