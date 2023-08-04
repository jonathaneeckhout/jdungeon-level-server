extends "res://scripts/entity.gd"

const CLASS = "MilkLady"

var behavior: Node = load("res://scripts/behaviors/wander.gd").new()
var shop: Node = load("res://scripts/shop.gd").new()


func _ready():
	super()
	$Interface/Name.text = CLASS

	server_synchronizer.type = server_synchronizer.ENTITY_TYPES.NPC

	add_child(behavior)
	behavior.init_wander()

	add_child(shop)
	shop.add_item_at_free_spot(load("res://scripts/items/apple.gd").new(), 20)
	shop.add_item_at_free_spot(load("res://scripts/items/meat.gd").new(), 50)
	shop.add_item_at_free_spot(load("res://scripts/items/healthPotion.gd").new(), 100)
	shop.add_item_at_free_spot(load("res://scripts/items/manaPotion.gd").new(), 100)


func fsm(delta):
	behavior.fsm_wander(delta)


func interact(from: CharacterBody2D):
	LevelsConnection.sync_shop.rpc_id(from.player, CLASS, shop.get_output())
