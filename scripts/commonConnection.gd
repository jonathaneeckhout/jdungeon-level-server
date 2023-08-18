extends Node

signal disconnected

const PING_INTERVAL_TIME = 5.0
const AUTHENTICATION_INTERVAL_TIME = 300.0

var auth_request = load("res://scripts/requests/authRequest.gd")
var auth_with_secret_request = load("res://scripts/requests/authWithSecretRequest.gd")
var get_ping_request = load("res://scripts/requests/getPingRequest.gd")
var get_character_request = load("res://scripts/requests/getCharacterRequest.gd")
var save_character_request = load("res://scripts/requests/saveCharacterRequest.gd")
var save_character_stats_request = load("res://scripts/requests/saveCharacterStatsRequest.gd")
var upload_level_info_request = load("res://scripts/requests/uploadLevelInfoRequest.gd")

var cookie = ""

var ping_timer: Timer
var authentication_timer: Timer


func _ready():
	# Periodically ping the server to check if it is still online
	ping_timer = Timer.new()
	ping_timer.autostart = false
	ping_timer.wait_time = PING_INTERVAL_TIME
	ping_timer.timeout.connect(_on_ping_timer_timeout)
	add_child(ping_timer)

	# Periodically authenticate to make sure the cookie is still valid
	authentication_timer = Timer.new()
	authentication_timer.autostart = false
	authentication_timer.wait_time = AUTHENTICATION_INTERVAL_TIME
	authentication_timer.timeout.connect(_on_authentication_timer_timeout)
	add_child(authentication_timer)


func start_ping_timer():
	print("Starting ping timer")
	ping_timer.start()


func stop_ping_timer():
	print("Stopping ping timer")
	ping_timer.stop()


func start_authentication_timer():
	print("Starting authentication timer")
	authentication_timer.start()


func stop_authentication_timer():
	print("Stopping authentication timer")
	authentication_timer.stop()


func authenticate():
	var new_req = auth_request.new()
	add_child(new_req)
	var res = await new_req.authenticate(Global.env_level, Global.env_secret)
	new_req.queue_free()
	print("Authentication level %s %s" % [Global.env_level, res["response"]])
	if res["response"]:
		cookie = res["cookie"]
	return res["response"]


func authenticate_player_with_secret(username: String, player_secret: String) -> bool:
	var new_req = auth_with_secret_request.new()
	add_child(new_req)
	var res = await new_req.authenticate_with_secret(username, player_secret, cookie)
	print("Authentication player %s %s" % [username, res])
	new_req.queue_free()
	return res


func get_ping():
	var new_req = get_ping_request.new()
	add_child(new_req)
	var res = await new_req.get_ping(cookie)
	new_req.queue_free()
	return res


func get_character(character_name: String):
	var new_req = get_character_request.new()
	add_child(new_req)
	var res = await new_req.get_character(character_name, cookie)
	new_req.queue_free()
	return res


func save_character(
	character_name: String,
	level_name: String,
	pos: Vector2,
	gold: int,
	inventory: Dictionary,
	equipment: Dictionary
):
	var new_req = save_character_request.new()
	add_child(new_req)
	var res = await new_req.save_character(
		character_name, level_name, pos, gold, inventory, equipment, cookie
	)
	new_req.queue_free()
	return res


func save_character_stats(character_name: String, current_level: int, experience: int):
	var new_req = save_character_stats_request.new()
	add_child(new_req)
	var res = await new_req.save_character_stats(character_name, current_level, experience, cookie)
	new_req.queue_free()
	return res


func upload_level_info(level_name: String, level_info: Dictionary) -> bool:
	var new_req = upload_level_info_request.new()
	add_child(new_req)
	var res = await new_req.upload_level_info(level_name, level_info, cookie)
	print("Uploaded level info %s" % [res])
	new_req.queue_free()
	return res


func _on_ping_timer_timeout():
	var res = await get_ping()
	if not res:
		print("Failed to ping common server")
		disconnected.emit()


func _on_authentication_timer_timeout():
	var res = await authenticate()
	if res:
		print("Authorized with common server")
