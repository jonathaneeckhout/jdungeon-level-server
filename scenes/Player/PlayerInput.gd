extends Node2D

@export var moving := false
@export var move_target := Vector2()

@export var interacting := false
var interact_target = ""

var last_processed_input = 0

@onready var player = $"../"


func _ready():
	LevelsConnection.player_moved.connect(_on_player_moved)
	LevelsConnection.player_interacted.connect(_on_player_interacted)


func reset_inputs():
	moving = false
	interacting = false


func _on_player_moved(id: int, input_sequence: int, pos: Vector2):
	if player.player != id:
		return

	# Ignore older inputs
	if input_sequence < last_processed_input:
		return

	last_processed_input = input_sequence

	moving = true
	move_target = pos


func _on_player_interacted(id: int, input_sequence: int, target: String):
	if player.player != id:
		return

	# Ignore older inputs
	if input_sequence < last_processed_input:
		return

	last_processed_input = input_sequence

	if $"../../../Enemies".has_node(target):
		interacting = true
		interact_target = $"../../../Enemies".get_node(target)
