extends Node

var auth_with_cookie_request = preload("res://scripts/requests/auth_with_cookie_request.gd")
var get_character_request = preload("res://scripts/requests/get_character_request.gd")


func authenticate_player_with_cookie(username: String, cookie: String) -> bool:
	var new_req = auth_with_cookie_request.new()
	add_child(new_req)
	var res = await new_req.authenticate_with_cookie(username, cookie)
	new_req.queue_free()
	return res

func get_character(character_name: String):
	var new_req = get_character_request.new()
	add_child(new_req)
	var res = await new_req.get_character(character_name)
	new_req.queue_free()
	return res