extends Node2D

@onready var level_env = Env.get_value("LEVEL")
@onready var level = $Level


# Called when the node enters the scene tree for the first time.
func _ready():
	LevelsConnection.logged_in.connect(_on_player_logged_in)
	level.set_level(level_env)

	# Add camera when running not runnig headless
	if not DisplayServer.get_name() == "headless":
		var camera_scene = load("res://scenes/Camera/Camera.tscn")
		var camera = camera_scene.instantiate()
		add_child(camera)


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
	level.add_player(id, character["name"], character["position"], character["experience_level"], character["experience"])

	LevelsConnection.add_player.rpc_id(id, id, character["name"], character["position"], character["experience_level"], character["experience"])
