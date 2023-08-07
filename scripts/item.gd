class_name Item extends Node

var healing = 0
var mana = 0

var consumable = false
var stackable = false
var equipable = false
var gold = false

var amount = 1
var price = 0
var max_stack_size = 10


func use(who: CharacterBody2D):
	if not consumable:
		return false

	if healing > 0:
		who.heal(healing)
	return true


func get_output():
	var output = {"uuid": name, "amount": amount, "price": price}

	return output
