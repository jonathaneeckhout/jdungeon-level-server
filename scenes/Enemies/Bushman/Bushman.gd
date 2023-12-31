extends "res://scripts/entity.gd"

const CLASS = "Bushman"

var behavior_script = load("res://scripts/behaviors/wander.gd")
var behavior: Node


func _init():
	max_hp = 20
	attack_power = 16
	experience = 100


func _ready():
	super()

	$Interface/Name.text = CLASS

	behavior = behavior_script.new()
	add_child(behavior)

	behavior.init_wander_and_attack()

	add_item_to_loottable("Gold", 0.5, 100)
	add_item_to_loottable("HealthPotion", 0.25, 1)


func fsm(delta):
	behavior.fsm_wander_and_attack(delta)
