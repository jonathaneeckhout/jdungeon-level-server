extends Node

const SIZE = 10

var equipment = []

@onready var root = $".."


func _ready():
	pass


func equip_item(item: Item):
	# TODO: implement equiping items
	print("Equiping item %s" % item.CLASS)
	return false


func add_item(item: Item):
	if not item.equipable:
		return false

	if equipment.size() >= SIZE:
		return false

	equipment.append(item)
	LevelsConnection.add_item_to_equipment.rpc_id(
		root.player, item.name, item.CLASS, item.equipment_slot
	)

	return true


func remove_item(item_uuid: String):
	var item = get_item(item_uuid)
	if item:
		equipment.erase(item)
		LevelsConnection.remove_item_from_equipment.rpc_id(root.player, item_uuid)
		return item


func get_item(item_uuid: String):
	for item in equipment:
		if item.name == item_uuid:
			return item


func get_output():
	var output = {"items": []}

	for item in equipment:
		var item_output = item.get_output()
		item_output["class"] = item.CLASS
		output["items"].append(item_output)

	return output


func load_items(items: Dictionary):
	for item_data in items["items"]:
		var item = Global.create_new_item(item_data["class"], item_data["amount"])
		if item:
			item.name = item_data["uuid"]
			equipment.append(item)


func _on_player_requested_inventory(id: int):
	if root.player != id:
		return

	LevelsConnection.sync_equipment.rpc_id(id, get_output())
