extends Node

signal team_list_changed
signal ready_list_changed	# When the ready list changes
signal player_list_changed	# A signal called when player list updates (client only)
signal player_updated(player:PlayerData)	# Not used but i cant be bothered to remove it
signal can_start_changed(status:bool)
signal game_started
signal game_ended

var player_list:Array[PlayerData]	# An array of current players connected
var team_list:Array[Team]			# An array of all teams that currently exist DOES NOT CONTAIN PLAYERS
var ready_list:PackedInt32Array		# An array of all players that are ready
var core_list:Array[BaseBuilding]
var ready_status:bool:
	set(value):
		if multiplayer.multiplayer_peer:
			if multiplayer.is_server():
				update_ready_status(multiplayer.get_unique_id(), value)
				rpc("update_ready_status", multiplayer.get_unique_id(), value)
			else:
				rpc("server_update_ready_status", multiplayer.get_unique_id(), value)
		ready_status = value
var can_start := false
var game_running := false
var left_game := false
var game_start_time
var game_end_time
var game_winner:int

var rand := RandomNumberGenerator.new()
var adj_list:WordList = ResourceLoader.load("res://menu/menu_resources/adjectives.tres")
var noun_list:WordList = ResourceLoader.load("res://menu/menu_resources/nouns.tres")

var enet_peer:ENetMultiplayerPeer

func host_server(port:int = 9998, players:int = 2):
	enet_peer = ENetMultiplayerPeer.new()
	var error = enet_peer.create_server(port, players - 1)
	if error != OK:
		printerr("Cannot host: " + str(error))
		return "Cannot host: " + str(error)
	multiplayer.multiplayer_peer = enet_peer
	if !multiplayer.peer_connected.is_connected(handle_connect):
		multiplayer.peer_connected.connect(handle_connect)
	if !multiplayer.peer_disconnected.is_connected(handle_disconnect):
		multiplayer.peer_disconnected.connect(handle_disconnect)
	
	print("Server hosted on port " + str(port))
	
	RTS.player.peer_id = multiplayer.get_unique_id()
	
	add_player_to_list(RTS.player)

func join_server(address:String = "localhost", port:int = 9998):
	enet_peer = ENetMultiplayerPeer.new()
	var error := enet_peer.create_client(address, port)
	if error != OK:
		printerr("Cannot host: " + str(error))
		return "Cannot host: " + str(error)
	multiplayer.multiplayer_peer = enet_peer
	if !multiplayer.connected_to_server.is_connected(connected_successfully):
		multiplayer.connected_to_server.connect(connected_successfully)
	if !multiplayer.connection_failed.is_connected(connection_failed):
		multiplayer.connection_failed.connect(connection_failed)

func connected_successfully():
	RTS.player.peer_id = multiplayer.get_unique_id()
	rpc("recieve_player_data", RTS.player.peer_id, RTS.player.username, RTS.player.team_id)
	get_tree().change_scene_to_file("res://menu/ready_screen.tscn")

func connection_failed():
	pass

@rpc("any_peer")	# Server recieve player data
func recieve_player_data(peer_id:int, username:String, team_id:int):#_player:PlayerData):
	if !multiplayer.is_server(): return
	print("SERVER RECIEVED PLAYER DATA FROM " + str(peer_id))
	var _player = get_player_from_peer_id(peer_id)
	if !_player: return #_player = PlayerData.new()
	
	#_player.peer_id = peer_id
	if _player.username != username:
		_player.username = username
		rpc("update_player_username", peer_id, username)
	if _player.team_id != team_id:
		_player.team_id = team_id
		rpc("update_player_team", peer_id, team_id)
		
	
	update_player_data(_player)
	#print_plr_list()

"""@rpc
func ask_player_data():
	rpc("recieve_player_data", RTS.player.peer_id, RTS.player.username, RTS.player.team_id)#RTS.player)"""

@rpc	# Client recieves player list
func recieve_player_list(usernames:PackedStringArray, peer_ids:PackedInt32Array, team_ids:PackedInt32Array):
	var list:Array[PlayerData]
	
	var i := 0
	for peer_id in peer_ids:
		var player := PlayerData.new()
		player.username = usernames[i]
		player.peer_id = peer_id
		player.team_id = team_ids[i]
		list.append(player)
		i += 1
	
	player_list = list
	
	#print_plr_list()
	emit_signal("player_list_changed")

@rpc
func update_player_username(peer_id:int, username:String):
	#print("UPDATED PLAYER " + str(peer_id) + " USERNAME")
	for i in player_list.size():
		if player_list[i].peer_id == peer_id:
			player_list[i].username = username
			#emit_signal("player_updated", player_list[i])
			emit_signal("player_list_changed")
			#print_plr_list()
			return

@rpc
func update_player_team(peer_id:int, team_id:int):
	#print("UPDATED PLAYER " + str(peer_id) + " TEAM")
	for i in player_list.size():
		if player_list[i].peer_id == peer_id:
			player_list[i].team_id = team_id
			#emit_signal("player_updated", player_list[i])
			emit_signal("player_list_changed")
			#print_plr_list()
			return

@rpc
func client_recieve_new_player(peer_id:int, team_id:int = -1, username:String = ""):
	for p in player_list: if p.peer_id == peer_id: return
	var player := PlayerData.new()
	player.peer_id = peer_id
	if team_id != -1 and username != "":
		player.team_id = team_id
		player.username = username
	
	add_player_to_list(player)

@rpc("any_peer")
func server_update_ready_status(peer_id:int, status:bool):
	if !multiplayer.is_server(): return
	rpc("update_ready_status", peer_id, status)
	update_ready_status(peer_id, status)

@rpc
func update_ready_status(peer_id:int, status:bool):
	if status:
		if !ready_list.has(peer_id):
			ready_list.append(peer_id)
			emit_signal("ready_list_changed")
	else:
		if ready_list.find(peer_id) != -1:
			ready_list.remove_at(ready_list.find(peer_id))
			emit_signal("ready_list_changed")

@rpc
func send_ready_list(_ready_list:PackedInt32Array):
	ready_list = _ready_list
	emit_signal("ready_list_changed")

func print_plr_list():
	if !OS.is_debug_build(): return
	if multiplayer.is_server():
		print("SERVER PLAYER LIST:")
		for player in player_list:
			print("")
			print(" - USERNAME " + player.username)
			print(" - PEER ID  " + str(player.peer_id))
			print(" - TEAM ID  " + str(player.team_id))
		return
	
	print("CLIENT " + str(multiplayer.get_unique_id()) + " PLAYER LIST")
	for player in player_list:
		print("")
		print(" - USERNAME " + player.username)
		print(" - PEER ID  " + str(player.peer_id))
		print(" - TEAM ID  " + str(player.team_id))
	

################################################################################

func handle_connect(peer_id:int):
	print("PLAYER " + str(peer_id) + " CONNECTED")
	
	var player := PlayerData.new()
	player.peer_id = peer_id
	add_player_to_list(player)
	
	#rpc_id(peer_id, "ask_player_data")
	send_team_list(peer_id)
	send_player_list(peer_id)
	rpc_id(peer_id, "send_ready_list", ready_list)
	rpc("client_recieve_new_player", peer_id)

func handle_disconnect(peer_id:int):
	print("PLAYER " + str(peer_id) + " DISCONNECTED")
	
	for i in player_list.size():
		if player_list[i].peer_id == peer_id:
			player_list.remove_at(i)
			emit_signal("player_list_changed")
			return

func send_team_list(peer_id:int):
	for team in team_list:
		rpc_id(peer_id, "client_recieve_new_team", team.name, team.slogan, team.color, team.id )
	
	return
	var team_names:PackedStringArray
	var team_ids:PackedInt32Array
	var team_slogans:PackedStringArray
	var team_colors:Array[Color]
	for team in team_list:
		team_names.append(team.name)
		team_ids.append(team.id)
		team_slogans.append(team.slogan)
		team_colors.append(team.color)
	
	rpc_id(peer_id, "recieve_team_list", team_names, team_ids, team_slogans, team_colors)

func send_player_list(peer_id:int):
	var usernames:PackedStringArray
	var peer_ids:PackedInt32Array
	var team_ids:PackedInt32Array
	for player in player_list:
		usernames.append(player.username)
		peer_ids.append(player.peer_id)
		team_ids.append(player.team_id)
	
	rpc_id(peer_id, "recieve_player_list", usernames, peer_ids, team_ids)

func add_player_to_list(_player:PlayerData):
	for player in player_list:
		if player.peer_id == _player.peer_id:
			return
		#if player.username == _player.username:
		#	return
	
	player_list.append(_player)
	emit_signal("player_list_changed")

func remove_player_from_list(_player:PlayerData) -> bool:
	var i := 0
	for player in player_list:
		if player.peer_id == _player.peer_id:
			player_list.remove_at(i)
			emit_signal("player_list_changed")
			return true
		i += 1
	
	return false

func update_player_data(_player:PlayerData):
	if !multiplayer.is_server():
		rpc("recieve_player_data", RTS.player.peer_id, RTS.player.username, RTS.player.team_id)
		return
	for i in player_list.size():
		if player_list[i].peer_id == _player.peer_id:
			player_list[i] = _player
			emit_signal("player_list_changed")
			#emit_signal("player_updated", null)#_player)
			rpc("update_player_team", RTS.player.peer_id, RTS.player.team_id)
			return

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

################################################################################

func _ready() -> void:
	rand.randomize()
	#set_default_team()
	RTS.client_player_updated.connect(update_player_data)
	#player_list_changed.connect(check_can_start)

func check_can_start() -> bool:
	var used_teams:Array[int]
	for player in player_list:
		if !ready_list.has(player.peer_id): return false
		if !get_team_from_id(player.team_id): return false
		if !used_teams.has(player.team_id): used_teams.append(player.team_id)
	if used_teams.size() > 4: return false
	return true

func get_all_used_teams() -> Array[int]:
	var used_teams:Array[int]
	for player in player_list:
		if !used_teams.has(player.team_id): used_teams.append(player.team_id)
	
	return used_teams

func set_default_team() -> void:
	new_team("TEAM 0", "", Color.BLUE, 0)
	new_team("TEAM 1", "", Color.RED, 1)

func new_team(team_name:String, slogan:String, color:Color, id:int = -1):
	var team = Team.new()
	if id < 0:
		id = hash(team_name)
	for a in team_list:
		if a.name == team_name or id == a.id:
			return "NAME OR ID TAKEN"
	
	team.name = team_name
	team.color = color
	team.id = id
	if multiplayer.is_server():
		team_list.append(team)
		rpc("client_recieve_new_team", team_name, slogan, color, id)
		emit_signal("team_list_changed")
	else:
		rpc("server_recieve_new_team", team_name, slogan, color, id)

@rpc("any_peer")
func server_recieve_new_team(team_name:String, slogan:String, color:Color, id:int = -1):
	if !multiplayer.is_server(): return
	
	new_team(team_name, slogan, color, id)

@rpc
func client_recieve_new_team(team_name:String, slogan:String, color:Color, id:int = -1):
	var team = Team.new()
	team.name = team_name
	team.color = color
	team.slogan = slogan
	team.id = id
	team_list.append(team)
	emit_signal("team_list_changed")

@rpc
func recieve_team_list(team_names:PackedStringArray, team_ids:PackedInt32Array, team_slogans:PackedStringArray, team_colors:Array[Color]):
	var list:Array[Team]
	
	for i in team_names.size():
		var team := Team.new()
		team.name = team_names[i]
		team.id = team_ids[i]
		team.slogan = team_slogans[i]
		team.color = team_colors[i]
	
	team_list = list
	emit_signal("team_list_changed")

func clear_unused_teams():
	var list:Array[int]		# Clears team list of unused teams
	var list2:Array[Team]
	for player in player_list:
		if !list.has(player.team_id): list.append(player.team_id)
	for i in list:
		list2.append(get_team_from_id(i))
	team_list = list2

################################################################################
# Multiplayer stuff above
# Other functions below
################################################################################

func random_team_name() -> String:
	var team_name:String
	
	if random_chance():
		team_name = "The "
	
	team_name += adj_list.list[int(rand.randi_range(0, adj_list.list.size() - 1))] + " "
	team_name += noun_list.list[int(rand.randi_range(0, noun_list.list.size() - 1))]
	
	var words = team_name.split(" ")                # Split the string into words
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

@rpc("reliable")
func start_game():
	if multiplayer.is_server():
		if !check_can_start(): return
		game_running = true
		print("GAME STARTED ON SERVER")
		
		#clear_unused_teams()
#		var i := 1
#		for player in player_list:
#			if player.peer_id == multiplayer.get_unique_id():
#				RTS.set_start_pos(i)
#			else:
#				RTS.rpc_id(player.peer_id, "set_start_pos", i)
#			i += 1
		
		game_start_time = Time.get_unix_time_from_system()
		rpc("start_game")
		RTS.pre_game_init()
		emit_signal("game_started")
	else:
		game_running = true
		game_start_time = Time.get_unix_time_from_system()
		print("GAME STARTED ON PEER " + str(multiplayer.get_unique_id()))
		RTS.pre_game_init()
		emit_signal("game_started")

@rpc("reliable")
func end_game():
	if !multiplayer.is_server():
		if !left_game:
			left_game = true
			game_end_time = Time.get_unix_time_from_system()
			
			game_ended.emit()
		return
	
	rpc("end_game")
	
	left_game = true
	game_end_time = Time.get_unix_time_from_system()
	game_ended.emit()
	

@rpc("reliable")
func eliminate(peer_id:int):
	if peer_id == multiplayer.get_unique_id():
		RTS.base_core = null
		RTS.core_death.emit()
		
		return
		
	#rpc("eliminate", peer_id)
	rpc_id(peer_id, "eliminate", peer_id)

func core_death(core:BaseBuilding):
	print("CORE DEATH " + str(core))
	print(str(core.peer_id))
	eliminate(core.peer_id)
	core_list.remove_at(core_list.find(core))
	if core_list.size() <= 1:
		set_winner(core_list[0].peer_id)
		end_game()
		print("WINNER")

@rpc
func set_winner(peer_id):
	if !multiplayer.is_server():
		game_winner = peer_id
		return
	
	rpc("set_winner", peer_id)
	game_winner = peer_id

func multiplayer_cleanup():
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	RTS.player.peer_id = 0
	RTS.player.team_id = 0
	RTS.materials = MaterialCost.new(0, 0, 0, 0)
	RTS.selected_building = null
	RTS.selected_list = []
	RTS.base_core = null
	RTS.selected_controllable = true
	RTS.start_position = 0
	player_list = []
	team_list = []
	ready_list = []
	core_list = []
	ready_status = false
	can_start = false
	game_running = false
	game_start_time = 0
	game_end_time = 0
	left_game = false
	game_winner = 0
