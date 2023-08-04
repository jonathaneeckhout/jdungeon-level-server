extends Node

const SIZE = Vector2(4, 4)

var shop = []
var gold = 0

@onready var root = $".."


func _ready():
	for x in range(SIZE.x):
		shop.append([])
		for y in range(SIZE.y):
			shop[x].append(null)


func add_item_at_free_spot(item: Item, price: int):
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			if shop[x][y] == null:
				item.price = price
				shop[x][y] = item
				var pos = Vector2(x, y)
				return pos

	return null


func set_item_at_pos(item: Item, pos: Vector2):
	var prev_item = shop[pos.x][pos.y]
	if prev_item:
		shop[pos.x][pos.y] = item
	return prev_item


func remove_item_at_pos(pos: Vector2):
	var item = shop[pos.x][pos.y]
	shop[pos.x][pos.y] = null
	return item


func get_output():
	var output = {"items": []}

	for x in range(SIZE.x):
		for y in range(SIZE.y):
			var item = shop[x][y]
			if item != null:
				var item_output = item.get_output()
				item_output["class"] = item.CLASS
				item_output["pos"] = {"x": x, "y": y}
				output["items"].append(item_output)

	return output
