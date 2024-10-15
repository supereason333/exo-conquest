@icon("res://icon.svg")
extends Node

var player_list:Array[PlayerData]	# An array of current players connected
var team_list:Array[Team]			# An array of all teams that currently exist DOES NOT CONTAIN PLAYERS

func host_server(port:int = 9998):
	pass

func join_server(address:String = "localhost", port:int = 9998):
	pass

################################################################################

func _ready() -> void:
	set_default_team()

func set_default_team() -> void:
	new_team("TEAM 0", Color.BLUE, 0)
	new_team("TEAM 1", Color.RED, 1)

func new_team(name:String, color:Color, id:int = -1):
	id = abs(id)
	var team = Team.new()
	for a in team_list:
		if a.name == name or id == a.id:
			return "NAME OR ID TAKEN"
	
	team.name = name
	team.color = color
	if id != -1:
		team.id = id
	else:
		team.id = hash(name)
	
	team_list.append(team)

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
