class_name Item extends Node

var healing = 0

var consumable = false
var stackable = false
var equipable = false

var max_stack_size = 10


func use(who: CharacterBody2D):
	if healing > 0:
		who.heal(healing)
	return true
