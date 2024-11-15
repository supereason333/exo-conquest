extends ScrollContainer

var Player_display := preload("res://menu/menu_resources/player_display.tscn")

@onready var list := $PanelContainer/List

func _ready() -> void:
	MultiplayerScript.player_list_changed.connect(update_player_list)
	MultiplayerScript.player_updated.connect(update_player)
	update_player_list()

func _process(delta: float) -> void:
	pass

func update_player(_player:PlayerData):
	for child in list.get_children():
		if child.peer_id == _player.peer_id:
			child.update()
			return

func update_player_list():
	if multiplayer.is_server(): print("SERVER UPDATED PLAYER LIST")
	else: print("CLIENT UPDATED PLAYER LIST")
	for child in list.get_children(): child.queue_free()
	for player in MultiplayerScript.player_list:
		var player_display := Player_display.instantiate()
		player_display.peer_id = player.peer_id
		list.add_child(player_display)
