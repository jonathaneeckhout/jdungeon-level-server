extends Node

var size = 1
var shop = []
var gold = 0

@onready var root = $".."


func _ready():
	LevelsConnection.shop_item_bought.connect(_on_shop_item_bought)


func add_item(item_class: String, price: int):
	if shop.size() >= size:
		return null

	var item = {
		"uuid": Global.uuid.v4(),
		"class": item_class,
		"price": price,
	}

	shop.append(item)
	return item


func get_item(item_uuid: String):
	for item in shop:
		if item["uuid"] == item_uuid:
			return item


func get_output():
	return {"items": shop}


func _on_shop_item_bought(id: int, vendor: String, item_uuid: String):
	if vendor != root.CLASS:
		return

	var player = Global.level.get_player_by_id(id)
	if player == null:
		return

	var item = get_item(item_uuid)
	if !item:
		return

	if player.inventory.pay_gold(item["price"]):
		var new_item = Global.create_new_item(item["class"], 1)
		if player.inventory.add_item_at_free_spot(new_item) == null:
			player.inventory.add_gold(item["price"])
