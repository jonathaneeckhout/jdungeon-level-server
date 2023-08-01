extends Node

const SIZE = Vector2(6, 6)

var inventory = []
var gold = 0

@onready var root = $".."


func _ready():
	for x in range(SIZE.x):
		var column = []
		for y in range(SIZE.y):
			column.append(null)
		inventory.append(column)

	LevelsConnection.inventory_item_used_at_pos.connect(_on_inventory_item_used_at_pos)


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
	inventory[pos.x][pos.y] = item
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


func _on_inventory_item_used_at_pos(grid_pos: Vector2):
	use_item_at_pos(grid_pos)
