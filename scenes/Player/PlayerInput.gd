extends Node2D

enum INTERACT_TYPES { ENEMY, NPC, ITEM }

@export var moving := false
@export var move_target := Vector2()

@export var interacting := false
var interact_target = ""
var interact_type = INTERACT_TYPES.ENEMY

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
		interact_type = INTERACT_TYPES.ENEMY
		return

	if $"../../../NPCS".has_node(target):
		interacting = true
		interact_target = $"../../../NPCS".get_node(target)
		interact_type = INTERACT_TYPES.NPC
		return

	if $"../../../Items".has_node(target):
		interacting = true
		interact_target = $"../../../Items".get_node(target)
		interact_type = INTERACT_TYPES.ITEM
		return
