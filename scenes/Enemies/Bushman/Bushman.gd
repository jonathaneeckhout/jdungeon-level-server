extends "res://scripts/entity.gd"

const CLASS = "Bushman"

var behavior_script = load("res://scripts/behaviors/wander.gd")
var behavior: Node


func _ready():
	super()

	$Interface/Name.text = CLASS

	behavior = behavior_script.new()
	add_child(behavior)

	behavior.init_wander_and_attack()


func fsm(delta):
	behavior.fsm_wander_and_attack(delta)
