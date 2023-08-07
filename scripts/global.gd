extends Node

const DROP_RANGE = 64

var uuid = load("res://scripts/uuid/uuid.gd")
var level: Node2D


func item_class_to_item(item_class: String):
	var item: Item
	match item_class:
		"HealthPotion":
			item = load("res://scripts/items/healthPotion.gd").new()
		"Gold":
			item = load("res://scripts/items/gold.gd").new()
		"ManaPotion":
			item = load("res://scripts/items/manaPotion.gd").new()
		"Apple":
			item = load("res://scripts/items/apple.gd").new()
		"Meat":
			item = load("res://scripts/items/meat.gd").new()

	return item


func create_new_item(item_class: String, amount: int):
	var item = item_class_to_item(item_class)
	if item:
		item.name = uuid.v4()
		item.amount = amount
	return item
