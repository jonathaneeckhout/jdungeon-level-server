extends Node

const PORT = 4434
const MAX_PEERS = 128


var cert = load("res://data/certs/level/X509_certificate.crt")
var key = load("res://data/certs/level/X509_key.key")
var players = {}


signal logged_in(id: int, username: String, character: String)

func _ready():
	var server = ENetMultiplayerPeer.new()

	server.create_server(PORT, MAX_PEERS)

	if server.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Failed to start levels server.")
		return

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
	var res = await Database.authenticate_player_with_cookie(username, cookie)

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
func add_player(_character_name: String, _pos: Vector2):
	#Placeholder code for server
	pass


@rpc("call_remote", "authority", "unreliable")
func sync_player(_character_name: String, _pos: Vector2, _vel : Vector2):
	pass
