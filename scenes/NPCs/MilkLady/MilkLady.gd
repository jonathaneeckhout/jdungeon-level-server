extends "res://scripts/entity.gd"

const CLASS = "MilkLady"

var behavior_script = load("res://scripts/behaviors/wander.gd")
var behavior: Node


func _ready():
	super()
	$Interface/Name.text = CLASS

	server_synchronizer.type = server_synchronizer.ENTITY_TYPES.NPC

	behavior = behavior_script.new()
	add_child(behavior)

	behavior.init_wander()


func fsm(delta):
	behavior.fsm_wander(delta)
