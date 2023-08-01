class_name Entity extends CharacterBody2D

signal died

const ATTACK_LOCK_TIME = 10.0
const DROP_RANGE = 64

var max_hp: float = 100.0
var hp: float = max_hp
var attack_power: float = 5.0
var experience = 100.0

var loot_money
var loot_table = []

var attacker: CharacterBody2D

var server_synchronizer: Node2D
var interface: Control

var attacker_lock_timer: Timer

var loot_scene = load("res://scenes/Loot/Loot.tscn")


func _ready():
	var server_synchronizer_scene = load("res://scenes/ServerSynchronizer/ServerSynchronizer.tscn")
	server_synchronizer = server_synchronizer_scene.instantiate()
	add_child(server_synchronizer)

	var interface_scene = load("res://scenes/Interface/interface.tscn")
	interface = interface_scene.instantiate()
	add_child(interface)

	attacker_lock_timer = Timer.new()
	attacker_lock_timer.one_shot = true
	attacker_lock_timer.wait_time = ATTACK_LOCK_TIME
	attacker_lock_timer.timeout.connect(_on_clock_attack_lock_timer_timeout)
	add_child(attacker_lock_timer)


func _physics_process(delta):
	fsm(delta)


func fsm(_delta):
	pass


func attack(target: CharacterBody2D):
	target.hurt(attack_power)
	server_synchronizer.sync_attack(position.direction_to(target.position))


func hurt(from: CharacterBody2D, damage: int):
	# Check who is attacking me
	if attacker == null:
		attacker = from

	# Reset the lock timer everytime I am hit by my attacker
	if attacker == from:
		attacker_lock_timer.start(ATTACK_LOCK_TIME)

	hp = max(0, hp - damage)

	if hp <= 0:
		die()
		return

	server_synchronizer.sync_hurt(hp, damage)
	update_hp_bar()


func die():
	if is_instance_valid(attacker):
		attacker.gain_experience(experience)

	drop_loot()

	died.emit()

	queue_free()


func drop_loot():
	for loot in loot_table:
		if randf() < loot["drop_rate"]:
			var item = loot_scene.instantiate()
			item.name = str(item.get_instance_id())
			item.item = loot["item"].new()
			item.item.amount = randi_range(1, loot["amount"])
			var random_x = randi_range(-DROP_RANGE, DROP_RANGE)
			var random_y = randi_range(-DROP_RANGE, DROP_RANGE)
			item.position = position + Vector2(random_x, random_y)
			$"../../Items".add_child(item)


func add_item_to_loottable(item_res_path: String, drop_rate: float, amount: int = 1):
	loot_table.append({"item": load(item_res_path), "drop_rate": drop_rate, "amount": amount})


# Adding this line to be in line with players
func gain_experience(_amount: int):
	pass


func update_hp_bar():
	$Interface/HPBar.value = (hp / max_hp) * 100


func _on_clock_attack_lock_timer_timeout():
	attacker = null
