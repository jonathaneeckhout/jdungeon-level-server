extends "res://scripts/entity.gd"

const CLASS = "Pebbleman"

var behavior_script = load("res://scripts/behaviors/wander.gd")
var behavior: Node


func _init():
	max_hp = 100
	attack_power = 56
	experience = 250


func _ready():
	super()

	$Interface/Name.text = CLASS

	behavior = behavior_script.new()
	add_child(behavior)

	behavior.init_wander_and_attack()

	add_item_to_loottable("Gold", 0.5, 350)
	add_item_to_loottable("HealthPotion", 0.25, 1)


func fsm(delta):
	behavior.fsm_wander_and_attack(delta)
