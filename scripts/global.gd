extends Node

const DROP_RANGE = 64

var uuid = load("res://scripts/uuid/uuid.gd")
var level: Node2D

var env_level: String
var env_secret: String
var env_port: int
var env_max_peers: int
var env_crt_path: String
var env_key_path: String
var env_debug: bool
var env_common_server_address: String


func load_env_variables():
	env_level = Env.get_value("LEVEL")
	if env_level == "":
		return false

	env_secret = Env.get_value("SECRET")
	if env_secret == "":
		return false

	var env_port_str = Env.get_value("LEVEL_PORT")
	if env_port_str == "":
		return false

	env_port = int(env_port_str)

	var env_max_peers_str = Env.get_value("LEVEL_MAX_PEERS")
	if env_max_peers_str == "":
		return false

	env_max_peers = int(env_max_peers_str)

	env_crt_path = Env.get_value("LEVEL_CRT")
	if env_crt_path == "":
		return false

	env_key_path = Env.get_value("LEVEL_KEY")
	if env_key_path == "":
		return false

	env_debug = Env.get_value("DEBUG") == "true"

	env_common_server_address = Env.get_value("COMMON_SERVER_ADDRESS")
	if env_common_server_address == "":
		return false

	return true


func item_class_to_item(item_class: String):
	var item: Item
	match item_class:
		"Gold":
			item = load("res://scripts/items/varia/gold.gd").new()

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
		"IronSword":
			item = load("res://scripts/items/equipment/weapons/ironsword.gd").new()

		"IronPlateArms":
			item = load("res://scripts/items/equipment/armours/ironplatearms.gd").new()
		"IronPlateBody":
			item = load("res://scripts/items/equipment/armours/ironplatebody.gd").new()
		"IronPlateBoots":
			item = load("res://scripts/items/equipment/armours/ironplateboots.gd").new()
		"IronPlateHelm":
			item = load("res://scripts/items/equipment/armours/ironplatehelm.gd").new()
		"IronPlateLegs":
			item = load("res://scripts/items/equipment/armours/ironplatelegs.gd").new()

		"WoolArms":
			item = load("res://scripts/items/equipment/armours/woolarms.gd").new()
		"WoolBody":
			item = load("res://scripts/items/equipment/armours/woolbody.gd").new()
		"WoolBoots":
			item = load("res://scripts/items/equipment/armours/woolboots.gd").new()
		"WoolHat":
			item = load("res://scripts/items/equipment/armours/woolhat.gd").new()
		"WoolLegs":
			item = load("res://scripts/items/equipment/armours/woollegs.gd").new()

	return item


func create_new_item(item_class: String, amount: int):
	var item = item_class_to_item(item_class)
	if item:
		item.name = uuid.v4()
		item.amount = amount
	return item
