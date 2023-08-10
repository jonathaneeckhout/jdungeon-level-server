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

	shop.size = 16
	add_child(shop)

	shop.add_item("Apple", 20)
	shop.add_item("Meat", 50)
	shop.add_item("HealthPotion", 100)
	shop.add_item("ManaPotion", 100)

	shop.add_item("IronSpear", 500)
	shop.add_item("IronSword", 300)

	shop.add_item("IronPlateArms", 250)
	shop.add_item("IronPlateBody", 750)
	shop.add_item("IronPlateBoots", 150)
	shop.add_item("IronPlateHelm", 200)
	shop.add_item("IronPlateLegs", 300)

	shop.add_item("WoolArms", 25)
	shop.add_item("WoolBody", 75)
	shop.add_item("WoolBoots", 15)
	shop.add_item("WoolHat", 20)
	shop.add_item("WoolLegs", 30)


func fsm(delta):
	behavior.fsm_wander(delta)


func interact(from: CharacterBody2D):
	LevelsConnection.sync_shop.rpc_id(from.player, CLASS, shop.get_output())
