extends Node2D

#Enemy scene that will be spawned at this position
@export var enemy_scene: Resource = null
#Time before respawn
#TODO: add some random part to be less predictable
@export var respawn_time := 0

var enemy: CharacterBody2D = null

@onready var respawn_timer = Timer.new()


# Called when the node enters the scene tree for the first time.
func _ready():

	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	respawn_timer.one_shot = true
	add_child(respawn_timer)

	#Spawn enemy at start
	respawn_timer.start()


func _on_enemy_died():
	respawn_timer.start(respawn_time)


func _on_respawn_timer_timeout():
	enemy = $"../../../".add_enemy(enemy_scene, position)
	enemy.died.connect(_on_enemy_died)
