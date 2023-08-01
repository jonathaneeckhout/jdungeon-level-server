extends "res://scripts/entity.gd"

const CLASS = "Sheep"

var behavior_script = load("res://scripts/behaviors/wander.gd")
var behavior: Node


func _ready():
	super()
	$Interface/Name.text = CLASS

	behavior = behavior_script.new()
	add_child(behavior)

	behavior.init_wander_and_flee()

	add_item_to_loottable("res://scripts/items/healthPotion.gd", 0.25, 1)


func fsm(delta):
	behavior.fsm_wander_and_flee(delta)
