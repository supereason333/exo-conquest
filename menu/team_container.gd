extends ScrollContainer

var Team_display := preload("res://game/player/team_display.tscn")

@onready var list := $PanelContainer/MarginContainer/List

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_list()
	MultiplayerScript.team_list_changed.connect(update_list)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_list():
	for child in list.get_children(): child.queue_free()
	for team in MultiplayerScript.team_list:
		var team_display := Team_display.instantiate()
		team_display.team = team
		list.add_child(team_display)
