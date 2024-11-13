@icon("res://icon.svg")
extends Node

signal team_list_changed

var player_list:Array[PlayerData]	# An array of current players connected
var team_list:Array[Team]			# An array of all teams that currently exist DOES NOT CONTAIN PLAYERS

var rand := RandomNumberGenerator.new()
var adj_list:WordList = ResourceLoader.load("res://menu/menu_resources/adjectives.tres")
var noun_list:WordList = ResourceLoader.load("res://menu/menu_resources/nouns.tres")

var enet_peer:ENetMultiplayerPeer

func host_server(port:int = 9998):
	enet_peer = ENetMultiplayerPeer.new()
	var error = enet_peer.create_server(port)
	if error != OK:
		printerr("Cannot host: " + str(error))
		return "Cannot host: " + str(error)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(handle_connect)
	multiplayer.peer_disconnected.connect(handle_disconnect)
	
	print("Server hosted on port " + str(port))
	
	RTS.player.peer_id = multiplayer.get_unique_id()
	
	add_player_to_list(RTS.player)

################################################################################

func join_server(address:String = "localhost", port:int = 9998):
	pass

func connected_successfully():
	pass

func connection_failed():
	pass

################################################################################

func handle_connect(peer_id:int):
	pass

func handle_disconnect(peer_id:int):
	pass


func add_player_to_list(player:PlayerData):
	pass

func remove_player_from_list(player:PlayerData):
	pass

################################################################################

func _ready() -> void:
	rand.randomize()
	set_default_team()

func set_default_team() -> void:
	new_team("TEAM 0", "", Color.BLUE, 0)
	new_team("TEAM 1", "", Color.RED, 1)

func new_team(name:String, slogan:String, color:Color, id:int = -1):
	id = abs(id)
	var team = Team.new()
	if id == -1:
		id = hash(name)
	for a in team_list:
		if a.name == name or id == a.id:
			return "NAME OR ID TAKEN"
	
	team.name = name
	team.color = color
	
	team_list.append(team)
	emit_signal("team_list_changed")

################################################################################
# Multiplayer stuff above
# Other functions below
################################################################################

func get_team_from_id(team_id) -> Team:
	for team in team_list:
		if team.id == team_id:
			return team
	
	return null

func get_team_members(team_id) -> Array[PlayerData]:
	var list:Array[PlayerData]
	for player in player_list:
		if player.team_id == team_id:
			list.append(player)
	
	return list

func get_player_from_peer_id(peer_id:int) -> PlayerData:
	for player in player_list:
		if player.peer_id == peer_id:
			return player
	
	return null

func get_player_from_username(username:String) -> PlayerData:
	for player in player_list:
		if player.username == username:
			return player
	
	return null

func random_team_name() -> String:
	var name:String
	
	if random_chance():
		name = "The "
	
	name += adj_list.list[int(rand.randi_range(0, adj_list.list.size() - 1))] + " "
	name += noun_list.list[int(rand.randi_range(0, noun_list.list.size() - 1))]
	
	var words = name.split(" ")                # Split the string into words
	var capitalized_words = []
	for word in words:
		capitalized_words.append(word.capitalize())  # Capitalize each word
	
	return " ".join(capitalized_words)

func random_chance(chance:float = 0.5) -> bool:
	if rand.randf() < chance:
		return true
	return false

func random_color(alpha:bool = false) -> Color:
	if alpha:
		return Color(rand.randf(), rand.randf(), rand.randf(), rand.randf())
	return Color(rand.randf(), rand.randf(), rand.randf())
