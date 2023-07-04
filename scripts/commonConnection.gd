extends Node

var auth_request = preload("res://scripts/requests/authRequest.gd")
var auth_with_cookie_request = preload("res://scripts/requests/auth_with_cookie_request.gd")
var get_character_request = preload("res://scripts/requests/getCharacterRequest.gd")


var cookie = ""
var logged_in = false

func _ready():
	var res = await authenticate("Grassland", "testpassword")
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
	print(res)
	return res["response"]


func authenticate_player_with_cookie(username: String, cookie: String) -> bool:
	var new_req = auth_with_cookie_request.new()
	add_child(new_req)
	var res = await new_req.authenticate_with_cookie(username, cookie)
	new_req.queue_free()
	return res


func get_character(character_name: String):
	var new_req = get_character_request.new()
	add_child(new_req)
	var res = await new_req.get_character(character_name, cookie)
	new_req.queue_free()
	return res
