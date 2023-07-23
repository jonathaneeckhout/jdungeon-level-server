extends Node2D

@onready var level_env = Env.get_value("LEVEL")
@onready var level = $Level


# Called when the node enters the scene tree for the first time.
func _ready():
	LevelsConnection.logged_in.connect(_on_player_logged_in)
	LevelsConnection.level_info_needed.connect(_on_level_info_needed)
	level.set_level(level_env)


func _on_player_logged_in(id: int, username: String, character_name: String):
	print("Player logged in %s" % username)
	# Get the player's character information
	var character = await CommonConnection.get_character(username)
	if character == null:
		print("Player=[%s], character=[%s] does not exist" % [username, character_name])
		multiplayer.disconnect_peer(id)
		return

	if character["level"] != level_env:
		print("Player=[%s], connected to the wrong level" % [username])
		multiplayer.disconnect_peer(id)
		return

	print("Adding character %s to level %s" % [character["name"], level_env])

	# Add the player to the level
	level.add_player(id, character["name"], character["position"])

	LevelsConnection.add_player.rpc_id(id, id, character["name"], character["position"])


func _on_level_info_needed(id: int):
	var info = level.get_info()
	LevelsConnection.load_level_response.rpc_id(id, info)
