extends Node

const SIZE = 36

var inventory = []
var gold = 0

var loot_scene = load("res://scenes/Loot/Loot.tscn")

@onready var root = $".."


func _ready():
	LevelsConnection.inventory_item_used.connect(_on_inventory_item_used)
	LevelsConnection.inventory_item_dropped.connect(_on_inventory_item_dropped)
	LevelsConnection.player_requested_inventory.connect(_on_player_requested_inventory)


func add_item(item: Item):
	if inventory.size() >= SIZE:
		return false

	inventory.append(item)
	LevelsConnection.add_item_to_inventory.rpc_id(root.player, item.name, item.CLASS)

	return true


func remove_item(item_uuid: String):
	var item = get_item(item_uuid)
	if item:
		inventory.erase(item)
		LevelsConnection.remove_item_from_inventory.rpc_id(root.player, item_uuid)
		return item


func get_item(item_uuid: String):
	for item in inventory:
		if item.name == item_uuid:
			return item


func use_item(item_uuid: String):
	var item = get_item(item_uuid)
	if item and item.use(root):
		remove_item(item_uuid)
		return true

	return false


func add_gold(amount: int):
	gold += amount
	LevelsConnection.sync_gold.rpc_id(root.player, gold)


func pay_gold(amount: int):
	if amount <= gold:
		gold -= amount
		LevelsConnection.sync_gold.rpc_id(root.player, gold)
		return true

	return false


func get_output():
	var output = {"items": []}

	for item in inventory:
		var item_output = item.get_output()
		item_output["class"] = item.CLASS
		output["items"].append(item_output)

	return output


func load_items(items: Dictionary):
	for item_data in items["items"]:
		var item = Global.create_new_item(item_data["class"], item_data["amount"])
		if item:
			item.name = item_data["uuid"]
			inventory.append(item)


func _on_inventory_item_used(id: int, item_uuid: String):
	if root.player != id:
		return

	use_item(item_uuid)


func _on_inventory_item_dropped(id: int, item_uuid: String):
	if root.player != id:
		return

	var item = get_item(item_uuid)
	if not item:
		return

	remove_item(item_uuid)

	var loot_item = loot_scene.instantiate()
	loot_item.name = str(loot_item.get_instance_id())
	loot_item.item = item
	var random_x = randi_range(-Global.DROP_RANGE, Global.DROP_RANGE)
	var random_y = randi_range(-Global.DROP_RANGE, Global.DROP_RANGE)
	loot_item.position = root.position + Vector2(random_x, random_y)
	Global.level.items.add_child(loot_item)


func _on_player_requested_inventory(id: int):
	if root.player != id:
		return

	LevelsConnection.sync_inventory.rpc_id(id, get_output())
