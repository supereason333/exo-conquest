extends BaseUnit


func _on_started_move() -> void:
	unit_sprite.play_anim("walk")


func _on_arrived() -> void:
	unit_sprite.play_anim("idle")
