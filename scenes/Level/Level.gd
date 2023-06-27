extends Node2D

const SYNC_PERIOD = 0.25

@onready var player_scene = load("res://scenes/Player/Player.tscn")

var level: String = ""
var players: Node2D
var npcs: Node2D
var enemies: Node2D

@onready var sync_timer = Timer.new()


func _ready():
	sync_timer.timeout.connect(_on_sync_timer_timeout)
	add_child(sync_timer)	
	sync_timer.start(SYNC_PERIOD)

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


func add_player(character_name: String, pos: Vector2):
	var player = player_scene.instantiate()
	player.name = character_name
	player.position = pos
	player.username = character_name
	players.add_child(player)


func _on_sync_timer_timeout():
	for player in players.get_children():
		#TODO: only send it to authorized clients
		LevelsConnection.sync_player.rpc(player.name, player.position, player.velocity)