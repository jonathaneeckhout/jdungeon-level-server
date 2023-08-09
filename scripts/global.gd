extends Node

const DROP_RANGE = 64

var uuid = load("res://scripts/uuid/uuid.gd")
var level: Node2D


func item_class_to_item(item_class: String):
	var item: Item
	match item_class:
		"Gold":
			item = load("res://scripts/items/gold.gd").new()

		"HealthPotion":
			item = load("res://scripts/items/consumables/healthPotion.gd").new()
		"ManaPotion":
			item = load("res://scripts/items/consumables/manaPotion.gd").new()
		"Apple":
			item = load("res://scripts/items/consumables/apple.gd").new()
		"Meat":
			item = load("res://scripts/items/consumables/meat.gd").new()

		"IronSpear":
			item = load("res://scripts/items/equipment/weapons/ironspear.gd").new()

		"IronPlateArms":
			item = load("res://scripts/items/equipment/armours/ironplatearms.gd").new()
		"IronPlateLegs":
			item = load("res://scripts/items/equipment/armours/ironplatelegs.gd").new()
	return item


func create_new_item(item_class: String, amount: int):
	var item = item_class_to_item(item_class)
	if item:
		item.name = uuid.v4()
		item.amount = amount
	return item
