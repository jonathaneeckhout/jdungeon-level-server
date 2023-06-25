extends Node

const PORT = 4434
const MAX_PEERS = 128


var cert = load("res://data/certs/X509_certificate.crt")
var key = load("res://data/certs/X509_key.key")
var players = {}
var server = ENetMultiplayerPeer.new()
var multiplayer_api : MultiplayerAPI

signal logged_in(id: int, username: String)

func _ready():
	server.peer_connected.connect(_client_connected)
	server.peer_disconnected.connect(_client_disconnected)

	server.create_server(PORT, MAX_PEERS)

	if server.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Failed to start levels server.")
		return

	var server_tls_options = TLSOptions.server(key, cert)

	var error = server.host.dtls_server_setup(server_tls_options)
	if error != OK:
		print("Failed to setup DTLS")
		return

	multiplayer_api = MultiplayerAPI.create_default_interface()
	get_tree().set_multiplayer(multiplayer_api, self.get_path())
	multiplayer_api.multiplayer_peer = server


func _process(_delta):
	if multiplayer_api.has_multiplayer_peer():
		multiplayer_api.poll()


func _client_connected(id):
	print("Client connected ", id)
	players[id] = {
		"username": "", "logged_in": false, "connected_time": Time.get_unix_time_from_system()
	}


func _client_disconnected(id):
	print("Client disconnected ", id)
	players.erase(id)


@rpc("call_remote", "any_peer", "reliable")
func authenticate_with_cookie(username: String, cookie: String):
	# Get the ID of remote peer
	var id = multiplayer_api.get_remote_sender_id()
	var res = await Database.authenticate_player_with_cookie(username, cookie)

	if res:
		# If authorization succeeded set logged_in to true for later reference
		players[id]["username"] = username
		players[id]["logged_in"] = true

		logged_in.emit(id, username)

	client_login_response.rpc_id(id, res)


@rpc("call_remote", "authority", "reliable")
func client_login_response(_succeeded: bool, _cookie: String):
	#Placeholder code for server
	pass
