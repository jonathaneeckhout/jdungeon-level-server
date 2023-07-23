extends Node2D

var level: String = ""
var players: Node2D
var npcs: Node2D
var enemies: Node2D
var terrain: Node2D
var player_respawn_locations: Node2D

var players_by_id = {}

@onready var player_scene = load("res://scenes/Player/Player.tscn")


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

	print("Setting level to %s" % level_name)

	var level_instance = scene.instantiate()
	self.add_child(level_instance)

	level = level_name
	players = level_instance.get_node("Entities/Players")
	npcs = level_instance.get_node("Entities/NPCS")
	enemies = level_instance.get_node("Entities/Enemies")
	terrain = level_instance.get_node("Entities/Terrain")
	player_respawn_locations = level_instance.get_node("PlayerRespawnLocations")

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
	if id in players_by_id:
		print("Removing player %s" % players_by_id[id].name)
		players_by_id[id].queue_free()
		players_by_id.erase(id)


func _client_disconnected(id):
	remove_player(id)


func add_enemy(enemy_scene: Resource, pos: Vector2) -> CharacterBody2D:
	var enemy = enemy_scene.instantiate()
	enemy.name = str(enemy.get_instance_id())
	enemy.position = pos
	enemies.add_child(enemy, true)
	return enemy


func find_player_respawn_location(pos: Vector2):
	var spots = player_respawn_locations.get_children()

	if len(spots) == 0:
		print("No player respawn spots found")
		return pos

	var closest = spots[0].position
	var closest_distance = closest.distance_to(pos)

	for spot in spots:
		var distance = spot.position.distance_to(pos)
		if distance < closest_distance:
			closest = spot.position
			closest_distance = distance

	return closest


func get_info():
	var info: Dictionary

	info["Terrain"] = []

	# TODO: optimalize this pieces, cache it in file or something
	for element in terrain.get_children():
		info["Terrain"].append(
			{"class": element.CLASS, "position": element.position}
		)

	return info
