extends Node

signal logged_in(id: int, username: String, character: String)
signal client_disconnected(id: int)
signal player_moved(id: int, input_sequence: int, pos: Vector2)
signal player_interacted(id: int, input_sequence: int, target: String)
signal player_requested_inventory(id: int)
signal inventory_item_used(id: int, item_uuid: String)
signal inventory_item_dropped(id: int, item_uuid: String)
signal shop_item_bought(id: int, vendor: String, item_uuid: String)
signal equipment_item_removed(id: int, item_uuid: String)
signal player_requested_equipment(id: int)
signal player_requested_stats(id: int)

var players = {}

@onready var port = int(Env.get_value("LEVEL_PORT"))
@onready var max_peers = int(Env.get_value("LEVEL_MAX_PEERS"))
@onready var crt_path = Env.get_value("LEVEL_CRT")
@onready var key_path = Env.get_value("LEVEL_KEY")


func _ready():
	var server = ENetMultiplayerPeer.new()

	server.create_server(port, max_peers)

	if server.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Failed to start levels server.")
		return

	var cert_file = FileAccess.open(crt_path, FileAccess.READ)
	var key_file = FileAccess.open(key_path, FileAccess.READ)

	var cert_string = cert_file.get_as_text()
	var key_string = key_file.get_as_text()

	var cert = X509Certificate.new()
	var key = CryptoKey.new()

	cert.load_from_string(cert_string)
	key.load_from_string(key_string)

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
		"username": "",
		"logged_in": false,
		"character": "",
		"connected_time": Time.get_unix_time_from_system()
	}


func _client_disconnected(id):
	print("Client disconnected ", id)
	players.erase(id)


@rpc("call_remote", "any_peer", "reliable")
func authenticate_with_secret(username: String, secret: String, character: String):
	# Get the ID of remote peer
	var id = multiplayer.get_remote_sender_id()

	var res = await CommonConnection.authenticate_player_with_secret(username, secret)
	if res:
		# If authorization succeeded set logged_in to true for later reference
		players[id]["username"] = username
		players[id]["logged_in"] = true
		players[id]["character"] = character

		logged_in.emit(id, username, character)

	client_login_response.rpc_id(id, res)


@rpc("call_remote", "authority", "reliable")
func client_login_response(_succeeded: bool, _cookie: String):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable") func add_player(
	_id: int,
	_character_name: String,
	_pos: Vector2,
	_current_level: int,
	_experience: int,
	_gold: int
):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable") func remove_player(_character_name: String):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable")
func add_other_player(_id: int, _character_name: String, _pos: Vector2, _hp: float):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable") func remove_other_player(_character_name: String):
	# Placeholder code for server
	pass


@rpc("call_remote", "any_peer", "reliable") func move(input_sequence: int, pos: Vector2):
	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not players[id]["logged_in"]:
		return

	player_moved.emit(id, input_sequence, pos)


@rpc("call_remote", "any_peer", "reliable") func interact(input_sequence: int, target: String):
	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not players[id]["logged_in"]:
		return

	player_interacted.emit(id, input_sequence, target)


@rpc("call_remote", "authority", "reliable")
func add_enemy(_enemy_name: String, _enemy_class: String, _pos: Vector2, _hp: float):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable") func remove_enemy(_enemy_name: String):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable")
func add_item(_item_name: String, _item_class: String, _pos: Vector2):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable") func remove_item(_item_name: String):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable")
func add_npc(_npc_name: String, _npc_class: String, _pos: Vector2, _hp: float):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable") func remove_npc(_npc_name: String):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable")
func add_item_to_inventory(_item_uuid: String, _item_class: String):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable") func remove_item_from_inventory(_item_uuid: String):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable") func sync_gold(_amount: int):
	# Placeholder code for server
	pass


@rpc("call_remote", "any_peer", "reliable") func use_inventory_item(item_uuid: String):
	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not players[id]["logged_in"]:
		return

	inventory_item_used.emit(id, item_uuid)


@rpc("call_remote", "any_peer", "reliable") func drop_inventory_item(item_uuid: String):
	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not players[id]["logged_in"]:
		return

	inventory_item_dropped.emit(id, item_uuid)


@rpc("call_remote", "any_peer", "reliable") func get_inventory():
	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not players[id]["logged_in"]:
		return

	player_requested_inventory.emit(id)


@rpc("call_remote", "authority", "reliable") func sync_inventory(_inventory: Dictionary):
	# Placeholder code for server
	pass


@rpc("call_remote", "any_peer", "reliable") func buy_shop_item(vendor: String, item_uuid: String):
	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not players[id]["logged_in"]:
		return

	shop_item_bought.emit(id, vendor, item_uuid)


@rpc("call_remote", "authority", "reliable") func sync_shop(_vendor: String, _shop: Dictionary):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable")
func equip_item(_equipment_slot: String, _item_uuid: String, _item_class: String):
	# Placeholder code for server
	pass


@rpc("call_remote", "authority", "reliable") func unequip_item(_equipment_slot: String):
	# Placeholder code for server
	pass


@rpc("call_remote", "any_peer", "reliable") func remove_equipment_item(item_uuid: String):
	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not players[id]["logged_in"]:
		return

	equipment_item_removed.emit(id, item_uuid)


@rpc("call_remote", "any_peer", "reliable") func get_equipment():
	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not players[id]["logged_in"]:
		return

	player_requested_equipment.emit(id)


@rpc("call_remote", "authority", "reliable") func sync_equipment(_inventory: Dictionary):
	# Placeholder code for server
	pass


@rpc("call_remote", "any_peer", "reliable") func get_stats():
	var id = multiplayer.get_remote_sender_id()

	# Only allow logged in players
	if not players[id]["logged_in"]:
		return

	player_requested_stats.emit(id)


@rpc("call_remote", "authority", "reliable") func sync_stats(_stats: Dictionary):
	# Placeholder code for server
	pass


@rpc("call_remote", "any_peer", "reliable") func fetch_server_time(client_time: float):
	var id = multiplayer.get_remote_sender_id()
	return_server_time.rpc_id(id, Time.get_unix_time_from_system(), client_time)


@rpc("call_remote", "authority", "reliable")
func return_server_time(_server_time: float, _client_time: float):
	# Placeholder code
	pass


@rpc("call_remote", "any_peer", "reliable") func get_latency(client_time: float):
	var id = multiplayer.get_remote_sender_id()
	return_latency.rpc_id(id, client_time)


@rpc("call_remote", "authority", "reliable") func return_latency(_client_time: float):
	# Placeholder code
	pass
