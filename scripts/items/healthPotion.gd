extends Item

const CLASS = "HealthPotion"


func _init():
	healing = 100
	consumable = true
	stackable = true
	max_stack_size = 10
