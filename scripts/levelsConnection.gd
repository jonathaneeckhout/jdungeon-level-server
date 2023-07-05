extends Node

@onready var port = int(Env.get_value("LEVEL_PORT"))
@onready var max_peers = int(Env.get_value("LEVEL_MAX_PEERS"))
@onready var crt_path = Env.get_value("LEVEL_CRT")
@onready var key_path = Env.get_value("LEVEL_KEY")

var players = {}

signal logged_in(id: int, username: String, character: String)
signal client_disconnected(id: int)
signal player_moved(id: int, pos: Vector2)
signal player_interacted(id: int, target: String)

func _ready():
	var server = ENetMultiplayerPeer.new()

	server.create_server(port, max_peers)

	if server.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Failed to start levels server.")
		return

	var cert = load(crt_path)
	var key = load(key_path)

	var server_tls_options = TLSOptions.server(key, cert)

	var error = server.host.dtls_server_setup(server_tls_options)
	if error != OK:
		print("Failed to setup DTLS")
		return

	multiplayer.multiplayer_peer = server
	multiplayer.peer_connected.connect(_client_connected)
	multiplayer.peer_disconnected.connect(_client_disconnected)


func _client_connected(id):
	print("Client connected ", id)
	players[id] = {
		"username": "", "logged_in": false, "character": "", "connected_time": Time.get_unix_time_from_system()
	}


func _client_disconnected(id):
	print("Client disconnected ", id)
	players.erase(id)


@rpc("call_remote", "any_peer", "reliable")
func authenticate_with_cookie(username: String, cookie: String, character: String):
	# Get the ID of remote peer
	var id = multiplayer.get_remote_sender_id()

	#TODO: bypass credentials now!!!!!!!!!!! IMPORTANT TO DO
	# var res = await CommonConnection.authenticate_player_with_cookie(username, cookie)
	var res = true

	if res:
		# If authorization succeeded set logged_in to true for later reference
		players[id]["username"] = username
		players[id]["logged_in"] = true
		players[id]["character"] = character

		logged_in.emit(id, username, character)

	client_login_response.rpc_id(id, res)


@rpc("call_remote", "authority", "reliable")
func client_login_response(_succeeded: bool, _cookie: String):
	#Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable")
func add_player(_id: int, _character_name: String, _pos: Vector2):
	#Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable")
func remove_player(_character_name: String):
	#Placeholder code for server
	pass


@rpc("call_remote", "any_peer", "reliable")
func move(pos):
	player_moved.emit(multiplayer.get_remote_sender_id(), pos)


@rpc("call_remote", "any_peer", "reliable")
func interact(target: String):
	player_interacted.emit(multiplayer.get_remote_sender_id(), target)


@rpc("call_remote", "authority", "reliable")
func add_enemy(_enemy_name: String, _pos: Vector2):
	#Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable")
func remove_enemy(_enemy_name: String):
	#Placeholder code for server
	pass
