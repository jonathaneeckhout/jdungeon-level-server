extends Node

signal logged_in

const AUTHENTICATION_INTERVAL_TIME = 300.0

var auth_request = load("res://scripts/requests/authRequest.gd")
var auth_with_secret_request = load("res://scripts/requests/authWithSecretRequest.gd")
var get_character_request = load("res://scripts/requests/getCharacterRequest.gd")
var save_character_request = load("res://scripts/requests/saveCharacterRequest.gd")
var save_character_stats_request = load("res://scripts/requests/saveCharacterStatsRequest.gd")
var upload_level_info_request = load("res://scripts/requests/uploadLevelInfoRequest.gd")

var cookie = ""

var authentication_timer: Timer

@onready var level = Env.get_value("LEVEL")
@onready var secret = Env.get_value("SECRET")


func _ready():
	var res = await authenticate(level, secret)
	if res:
		print("Authorized with common server")

	# Periodically authenticate to make sure the cookie is still valid
	authentication_timer = Timer.new()
	authentication_timer.autostart = true
	authentication_timer.wait_time = AUTHENTICATION_INTERVAL_TIME
	authentication_timer.timeout.connect(_on_authentication_timer_timeout)
	add_child(authentication_timer)


func authenticate(level_name: String, key: String):
	var new_req = auth_request.new()
	add_child(new_req)
	var res = await new_req.authenticate(level, key)
	new_req.queue_free()
	print("Authentication level %s %s" % [level_name, res["response"]])
	if res["response"]:
		cookie = res["cookie"]
		logged_in.emit()
	return res["response"]


func authenticate_player_with_secret(username: String, player_secret: String) -> bool:
	var new_req = auth_with_secret_request.new()
	add_child(new_req)
	var res = await new_req.authenticate_with_secret(username, player_secret, cookie)
	print("Authentication player %s %s" % [username, res])
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


func _on_authentication_timer_timeout():
	var res = await authenticate(level, secret)
	if res:
		print("Authorized with common server")
