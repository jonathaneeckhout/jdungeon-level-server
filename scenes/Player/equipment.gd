extends Node

const SIZE = 10

var equipment = {
	"Head": null,
	"Body": null,
	"Legs": null,
	"Arms": null,
	"Feet": null,
	"RightHand": null,
	"LeftHand": null,
	"Ring1": null,
	"Ring2": null,
	"Neck": null,
}

@onready var root = $".."


func _ready():
	LevelsConnection.equipment_item_removed.connect(_on_equipment_item_removed)
	LevelsConnection.player_requested_equipment.connect(_on_player_requested_equipment)


func equip_item(item: Item):
	print("Equiping item %s" % item.CLASS)
	if not equipment.has(item.equipment_slot):
		return false

	if equipment[item.equipment_slot] != null:
		unequip_item(item.name)

	equipment[item.equipment_slot] = item

	LevelsConnection.equip_item.rpc_id(root.player, item.equipment_slot, item.name, item.CLASS)

	# TODO: update player stats

	return true


func unequip_item(item_uuid: String):
	for equipment_slot in equipment:
		var item = equipment[equipment_slot]
		if item != null and item.name == item_uuid:
			equipment[equipment_slot] = null

			LevelsConnection.unequip_item.rpc_id(root.player, equipment_slot)

			root.inventory.add_item(item)

			# TODO: update player stats

			return item


func get_item(item_uuid: String):
	for equipment_slot in equipment:
		var item = equipment[equipment_slot]
		if item != null and item.name == item_uuid:
			return item


func get_output():
	var output = {"equipment": {}}

	for equipment_slot in equipment:
		var item = equipment[equipment_slot]
		if item != null:
			output["equipment"][equipment_slot] = item.get_output()
			output["equipment"][equipment_slot]["class"] = item.CLASS

	return output


func load_items(items: Dictionary):
	for equipment_slot in items["equipment"]:
		if not equipment.has(equipment_slot):
			continue

		var item_data = items["equipment"][equipment_slot]
		var item = Global.create_new_item(item_data["class"], item_data["amount"])
		if item:
			item.name = item_data["uuid"]
			equip_item(item)


func _on_player_requested_equipment(id: int):
	if root.player != id:
		return

	LevelsConnection.sync_equipment.rpc_id(id, get_output())


func _on_equipment_item_removed(id: int, item_uuid: String):
	if root.player != id:
		return

	unequip_item(item_uuid)
