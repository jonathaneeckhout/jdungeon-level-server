extends "res://scripts/entity.gd"

const CLASS = "Wolf"

var behavior_script = load("res://scripts/behaviors/wander.gd")
var behavior: Node


func _init():
	max_hp = 14
	attack_power = 3
	experience = 70


func _ready():
	super()

	$Interface/Name.text = CLASS

	behavior = behavior_script.new()
	add_child(behavior)

	behavior.init_wander_and_attack()

	add_item_to_loottable("Meat", 0.40, 1)


func fsm(delta):
	behavior.fsm_wander_and_attack(delta)
