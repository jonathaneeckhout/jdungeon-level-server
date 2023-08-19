extends Node2D

var level: String = ""
var level_instance: Node2D
var players: Node2D
var npcs: Node2D
var enemies: Node2D
var items: Node2D
var terrain: Node2D
var player_respawn_locations: Node2D
var tilemap: TileMap

var players_by_id = {}

@onready var player_scene = load("res://scenes/Player/Player.tscn")


func _ready():
	Global.level = self

	LevelsConnection.started.connect(_on_levelsconnection_started)
	LevelsConnection.stopped.connect(_on_levelsconnection_stopped)

	LevelsConnection.logged_in.connect(_on_player_logged_in)
	multiplayer.peer_disconnected.connect(_client_disconnected)


func set_level(level_name: String):
	var scene

	match level_name:
		"Grassland":
			scene = load("res://scenes/Levels/Grassland/Grassland.tscn")
		_:
			print("Level %s does not exist" % level_name)
			return false

	print("Setting level to %s" % level_name)

	level_instance = scene.instantiate()
	self.add_child(level_instance)

	level = level_name
	players = level_instance.get_node("Entities/Players")
	npcs = level_instance.get_node("Entities/NPCS")
	enemies = level_instance.get_node("Entities/Enemies")
	items = level_instance.get_node("Entities/Items")
	terrain = level_instance.get_node("Entities/Terrain")
	player_respawn_locations = level_instance.get_node("PlayerRespawnLocations")
	tilemap = level_instance.get_node("TileMap")

	return true


func add_player(
	id: int,
	character_name: String,
	pos: Vector2,
	stats: Dictionary,
	inventory: Dictionary,
	equipment: Dictionary
):
	var player = player_scene.instantiate()
	player.player = id
	player.name = character_name
	player.level = level
	player.position = pos
	player.username = character_name

	player.stats.load_stats(stats)

	players.add_child(player)
	# Add to this list for internal tracking
	players_by_id[id] = player

	player.inventory.load_inventory(inventory)
	player.equipment.load_items(equipment)

	player.stats.update_stats()


func remove_player(id: int):
	if id in players_by_id:
		print("Removing player %s" % players_by_id[id].name)
		players_by_id[id].queue_free()
		players_by_id.erase(id)


func remove_all_players():
	for id in players_by_id:
		remove_player(id)


func get_player_by_id(id: int):
	if id in players_by_id:
		return players_by_id[id]
	else:
		return null


func _client_disconnected(id):
	if id in players_by_id:
		CommonConnection.save_character(
			players_by_id[id].name,
			level,
			players_by_id[id].position,
			players_by_id[id].stats.get_output(),
			players_by_id[id].inventory.get_output(),
			players_by_id[id].equipment.get_output()
		)
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
	var info: Dictionary = {}

	info["terrain"] = []

	for element in terrain.get_children():
		info["terrain"].append(
			{"class": element.CLASS, "position": {"x": element.position.x, "y": element.position.y}}
		)

	info["tilemap"] = get_tilemap_info()

	return info


func get_tilemap_info():
	var info: Array = []

	for layer in tilemap.get_layers_count():
		var data = []
		var tilemap_rect = tilemap.get_used_rect()

		for x in range(tilemap_rect.position.x, tilemap_rect.end.x):
			for y in range(tilemap_rect.position.y, tilemap_rect.end.y):
				var coords = Vector2(x, y)
				var source_id = tilemap.get_cell_source_id(layer, coords)
				if source_id != -1:
					var atlas_coords = tilemap.get_cell_atlas_coords(layer, coords)
					data.append(
						{
							"co": {"x": coords.x, "y": coords.y},
							"sid": source_id,
							"aco": {"x": atlas_coords.x, "y": atlas_coords.y}
						}
					)

		info.append({"layer": layer, "data": data})

	return info


func _on_levelsconnection_started():
	pass


func _on_levelsconnection_stopped():
	# Remove all players when the server is not running
	remove_all_players()


func _on_player_logged_in(id: int, username: String, character_name: String):
	print("Player logged in %s" % username)
	# Get the player's character information
	var character = await CommonConnection.get_character(username)
	if character == null:
		print("Player=[%s], character=[%s] does not exist" % [username, character_name])
		multiplayer.disconnect_peer(id)
		return

	if character["level"] != level:
		print("Player=[%s], connected to the wrong level" % [username])
		multiplayer.disconnect_peer(id)
		return

	print("Adding character %s to level %s" % [character["name"], level])

	# Add the player to the level
	add_player(
		id,
		character["name"],
		character["position"],
		character["stats"],
		character["inventory"],
		character["equipment"]
	)

	LevelsConnection.add_player.rpc_id(id, id, character["name"], character["position"])
