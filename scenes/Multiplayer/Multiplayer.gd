extends Node2D

const LEVEL = "Grassland"

@onready var level = $Level

# Called when the node enters the scene tree for the first time.
func _ready():
	LevelsConnection.logged_in.connect(_on_player_logged_in)
	level.set_level(LEVEL)

func _on_player_logged_in(id: int, username: String, character_name: String):
	print("Player logged in %s" % username)
	# Get the player's character information
	var character = await Database.get_character(username)
	if character == null:
		print("Player=[%s], character=[%s] does not exist" %[username, character_name])
		#TODO: disconnect client
		return
	
	if character["level"] != LEVEL:
		print("Player=[%s], connected to the wrong level" %[username])
		multiplayer.disconnect_peer(id)
		return

	# Add the player to the level
	level.add_player(character["name"], character["position"])

	LevelsConnection.add_player.rpc_id(id, character["name"], character["position"])

	# Add the player to the player
