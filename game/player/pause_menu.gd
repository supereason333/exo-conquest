extends PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		visible = !visible


func _on_exit_title_button_pressed() -> void:
	MultiplayerScript.end_game()


func _on_exit_game_button_pressed() -> void:
	MultiplayerScript.end_game()
	get_tree().quit()
