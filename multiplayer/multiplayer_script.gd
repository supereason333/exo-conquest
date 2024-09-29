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
	var a := Team.new()
	a.color = Color.BLUE
	a.name = "TEAM 0"
	a.id = 0
	
	team_list.append(a)

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
