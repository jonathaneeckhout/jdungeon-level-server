class_name Entity extends CharacterBody2D

signal died

var max_hp: float = 100.0
var hp: float = max_hp
var attack_power: float = 5.0

var server_synchronizer: Node2D
var interface: Control


func _ready():
	var server_synchronizer_scene = load("res://scenes/ServerSynchronizer/ServerSynchronizer.tscn")
	server_synchronizer = server_synchronizer_scene.instantiate()
	add_child(server_synchronizer)

	var interface_scene = load("res://scenes/Interface/interface.tscn")
	interface = interface_scene.instantiate()
	add_child(interface)


func _physics_process(delta):
	fsm(delta)


func fsm(_delta):
	pass


func attack(target: CharacterBody2D):
	target.hurt(attack_power)


func hurt(damage: int):
	hp = max(0, hp - damage)

	if hp <= 0:
		died.emit()
		queue_free()
		return

	server_synchronizer.sync_hurt(hp, damage)
	update_hp_bar()


func update_hp_bar():
	$Interface/HPBar.value = (hp / max_hp) * 100
