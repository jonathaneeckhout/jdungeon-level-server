class_name Item extends Node

var healing = 0
var mana = 0

var consumable = false
var stackable = false
var equipable = false
var equipment_slot = ""
var gold = false

var amount = 1
var price = 0
var max_stack_size = 10

var defense = 0
var attack = 0


func use(who: CharacterBody2D):
	if consumable:
		if healing > 0:
			who.heal(healing)
		return true
	elif equipable:
		return who.equip_item(self)
	else:
		return false


func get_output():
	var output = {"uuid": name, "amount": amount, "price": price}

	if equipable:
		output["equipment_slot"] = equipment_slot
		output["defense"] = defense
		output["attack"] = attack

	return output
