extends Node

var auth_request = preload("res://scripts/requests/authRequest.gd")
var auth_with_secret_request = preload("res://scripts/requests/authWithSecretRequest.gd")
var get_character_request = preload("res://scripts/requests/getCharacterRequest.gd")

@onready var level = Env.get_value("LEVEL")
@onready var secret = Env.get_value("SECRET")

var cookie = ""
var logged_in = false

func _ready():
	var res = await authenticate(level, secret)
	if res:
		print("Authorized with server")

func authenticate(level: String, key: String):
	var new_req = auth_request.new()
	add_child(new_req)
	var res = await new_req.authenticate(level, key)
	new_req.queue_free()
	if res["response"]:
		logged_in = true
		cookie = res["cookie"]
	return res["response"]


func authenticate_player_with_secret(username: String, secret: String) -> bool:
	var new_req = auth_with_secret_request.new()
	add_child(new_req)
	var res = await new_req.authenticate_with_secret(username, secret, cookie)
	new_req.queue_free()
	return res


func get_character(character_name: String):
	var new_req = get_character_request.new()
	add_child(new_req)
	var res = await new_req.get_character(character_name, cookie)
	new_req.queue_free()
	return res
