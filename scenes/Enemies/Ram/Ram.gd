extends "res://scripts/entity.gd"

const CLASS = "Ram"

var behavior_script = load("res://scripts/behaviors/wander.gd")
var behavior: Node

func _ready():
	super()
	$Interface/Name.text = CLASS

	behavior = behavior_script.new()
	add_child(behavior)


func fsm(delta):
	behavior.fsm_wander(delta)