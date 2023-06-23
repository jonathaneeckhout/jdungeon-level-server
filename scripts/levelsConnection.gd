extends Node

const SERVER_ADDRESS = "127.0.01"
const SERVER_PORT = 4434

var cert = load("res://data/certs/X509_certificate_levels.crt")

var client = ENetMultiplayerPeer.new()
var multiplayer_api : MultiplayerAPI

func _ready():

	var error = client.create_client(SERVER_ADDRESS, SERVER_PORT)
	if error != OK:
		print("Error while creating")
		return false

	if client.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Failed to connect to game")
		# OS.alert("Failed to start multiplayer client.")
		return false

	#TODO: Use this function instead of debug function
	# var client_tls_options = TLSOptions.client(cert)
	#TODO: Remove next line
	var client_tls_options = TLSOptions.client_unsafe(cert)
	error = client.host.dtls_client_setup(SERVER_ADDRESS, client_tls_options)
	if error != OK:
		print("Failed to connect via DTLS")
		return false

	multiplayer_api = MultiplayerAPI.create_default_interface()
	get_tree().set_multiplayer(multiplayer_api, self.get_path()) 
	multiplayer_api.multiplayer_peer = client

	multiplayer_api.connected_to_server.connect(_on_connection_succeeded)
	multiplayer_api.connection_failed.connect(_on_connection_failed)


func _on_connection_succeeded():
	print("Levels connection succeeded")
	register_level.rpc_id(1, "Grassland", PlayersConnection.ADDRESS, PlayersConnection.PORT)


func _on_connection_failed():
	print("Levels connection failed")


@rpc("call_remote", "any_peer", "reliable")
func register_level(_level: String, _address: String, _port: int):
	pass
