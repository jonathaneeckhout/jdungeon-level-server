extends Node

const SIZE = Vector2(6, 6)

var inventory = []


func _ready():
	for x in range(SIZE.x):
		var column = []
		for y in range(SIZE.y):
			column.append(null)
		inventory.append(column)


func add_item_at_free_spot(item: Item):
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			if inventory[x][y] == null:
				inventory[x][y] = item
				return true

	return false


func set_item_at_pos(item: Item, pos: Vector2):
	var prev_item = inventory[pos.x][pos.y]
	inventory[pos.x][pos.y] = item
	return prev_item


func remove_item_at_pos(pos: Vector2):
	return inventory[pos.x][pos.y]


func use_item_at_pos(pos: Vector2):
	var item = inventory[pos.x][pos.y]
	if item and item.use():
		remove_item_at_pos(pos)
		return true

	return false
