extends Node2D

@onready var player_scene = load("res://scenes/Player/Player.tscn")

var level: String = ""
var players: Node2D
var npcs: Node2D
var enemies: Node2D

var players_by_id = {}

func _ready():
	multiplayer.peer_disconnected.connect(_client_disconnected)

func set_level(level_name: String):
	var scene

	match level_name:
		"Grassland":
			scene = load("res://scenes/Levels/Grassland/Grassland.tscn")
		"_":
			print("Level %s does not exist" % level_name)
			return false

	var level_instance = scene.instantiate()
	self.add_child(level_instance)

	level = level_name
	players = level_instance.get_node("Players")
	npcs = level_instance.get_node("NPCS")
	enemies = level_instance.get_node("Enemies")

	return true


func add_player(id: int, character_name: String, pos: Vector2):
	var player = player_scene.instantiate()
	player.player = id
	player.name = character_name
	player.position = pos
	player.username = character_name
	players.add_child(player)
	# Add to this list for internal tracking
	players_by_id[id] = player


func remove_player(id: int):
	if players_by_id[id]:
		print("Removing player %s" % players_by_id[id].name)
		players_by_id[id].queue_free()
		players_by_id.erase(id)

func _client_disconnected(id):
	remove_player(id)