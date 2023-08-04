extends Item

const CLASS = "ManaPotion"


func _init():
	mana = 100
	consumable = true
	stackable = true
	max_stack_size = 10
