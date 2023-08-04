extends Node

const SIZE = Vector2(6, 6)

var inventory = []
var gold = 0

@onready var root = $".."


func _ready():
	for x in range(SIZE.x):
		inventory.append([])
		for y in range(SIZE.y):
			inventory[x].append(null)

	LevelsConnection.inventory_item_used_at_pos.connect(_on_inventory_item_used_at_pos)
	LevelsConnection.player_requested_inventory.connect(_on_player_requested_inventory)


func add_item_at_free_spot(item: Item):
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			if inventory[x][y] == null:
				inventory[x][y] = item
				var pos = Vector2(x, y)
				LevelsConnection.add_item_to_inventory.rpc_id(root.player, item.CLASS, pos)
				return pos

	return null


func set_item_at_pos(item: Item, pos: Vector2):
	var prev_item = inventory[pos.x][pos.y]
	if prev_item:
		LevelsConnection.remove_item_from_inventory.rpc_id(root.player, pos)
	inventory[pos.x][pos.y] = item
	LevelsConnection.add_item_to_inventory.rpc_id(root.player, item.CLASS, pos)
	return prev_item


func remove_item_at_pos(pos: Vector2):
	var item = inventory[pos.x][pos.y]
	inventory[pos.x][pos.y] = null
	LevelsConnection.remove_item_from_inventory.rpc_id(root.player, pos)
	return item


func use_item_at_pos(pos: Vector2):
	var item = inventory[pos.x][pos.y]
	if item and item.use(root):
		remove_item_at_pos(pos)
		return true

	return false


func add_gold(amount: int):
	gold += amount
	LevelsConnection.sync_gold.rpc_id(root.player, gold)


func get_output():
	var output = {"items": []}

	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var item = inventory[x][y]
			if item != null:
				var item_output = item.get_output()
				item_output["class"] = item.CLASS
				item_output["pos"] = {"x": x, "y": y}
				output["items"].append(item_output)

	return output


func load_items(items: Dictionary):
	for item_data in items["items"]:
		match item_data["class"]:
			"HealthPotion":
				var item = load("res://scripts/items/healthPotion.gd").new()
				item.amount = item_data["amount"]
				inventory[item_data["pos"]["x"]][item_data["pos"]["y"]] = item


func _on_inventory_item_used_at_pos(id: int, grid_pos: Vector2):
	if root.player != id:
		return

	use_item_at_pos(grid_pos)


func _on_player_requested_inventory(id: int):
	if root.player != id:
		return

	LevelsConnection.sync_inventory.rpc_id(id, get_output())
