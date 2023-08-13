extends "res://scripts/entity.gd"

const CLASS = "Sheep"

var behavior_script = load("res://scripts/behaviors/wander.gd")
var behavior: Node


func _init():
	max_hp = 10
	attack_power = 1
	experience = 50


func _ready():
	super()
	$Interface/Name.text = CLASS

	behavior = behavior_script.new()
	add_child(behavior)

	behavior.init_wander_and_flee()

	add_item_to_loottable("Meat", 0.25, 1)


func fsm(delta):
	behavior.fsm_wander_and_flee(delta)
