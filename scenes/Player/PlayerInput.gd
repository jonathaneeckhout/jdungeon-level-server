extends Node2D

@export var moving := false
@export var move_target := Vector2()

@export var interacting := false
var interact_target = ""

@onready var player = $"../"

func _ready():
	LevelsConnection.player_moved.connect(_on_player_moved)
	LevelsConnection.player_interacted.connect(_on_player_interacted)


func reset_inputs():
	moving = false
	interacting = false


func _on_player_moved(id: int, pos):
	if player.player != id:
		return

	moving = true
	move_target = pos

func _on_player_interacted(id: int, target: String):
	if player.player != id:
		return

	if $"../../../Enemies".has_node(target):
		interacting = true
		interact_target = $"../../../Enemies".get_node(target)
