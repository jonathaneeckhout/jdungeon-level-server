extends Node2D

const EXPIRE_TIME: float = 30.0

@export var item: Item:
	set(new_item):
		item = new_item
		$Label.text = new_item.CLASS

var expire_timer = Timer.new()
var server_synchronizer: Node2D


func _ready():
	var server_synchronizer_scene = load("res://scenes/ServerSynchronizer/ServerSynchronizer.tscn")
	server_synchronizer = server_synchronizer_scene.instantiate()
	server_synchronizer.type = server_synchronizer.ENTITY_TYPES.ITEM
	add_child(server_synchronizer)

	expire_timer.one_shot = true
	expire_timer.autostart = true
	expire_timer.wait_time = EXPIRE_TIME
	expire_timer.timeout.connect(_on_expire_timer_timeout)
	add_child(expire_timer)


func interact(from: CharacterBody2D):
	var pos = from.inventory.add_item_at_free_spot(item)

	if pos != null:
		LevelsConnection.add_item_to_inventory.rpc_id(from.player, item.CLASS, pos)
		queue_free()


func _on_expire_timer_timeout():
	queue_free()
