class_name Entity extends CharacterBody2D

signal died

const ATTACK_LOCK_TIME = 10.0

var max_hp: int = 10
var hp: int = 0
var attack_power: int = 1:
	set(value):
		attack_power = value
		min_attack_power = int((attack_power * 60) / 100)

var min_attack_power: int = 0
var experience = 100

var loot_money
var loot_table = []

var attacker: CharacterBody2D

var server_synchronizer: Node2D
var interface: Control

var attacker_lock_timer: Timer

var loot_scene = load("res://scenes/Loot/Loot.tscn")


func _ready():
	hp = max_hp

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
	var damage = randi_range(min_attack_power, attack_power)

	target.hurt(damage)

	server_synchronizer.sync_attack(position.direction_to(target.position))


func hurt(from: CharacterBody2D, damage: int):
	# Check who is attacking me
	if attacker == null:
		attacker = from

	# Reset the lock timer everytime I am hit by my attacker
	if attacker == from:
		attacker_lock_timer.start(ATTACK_LOCK_TIME)

	hp = max(0, hp - damage)

	server_synchronizer.sync_hurt(hp, damage)

	if hp <= 0:
		die()
		return

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
			var loot_item = loot_scene.instantiate()
			loot_item.name = str(loot_item.get_instance_id())
			loot_item.item = Global.create_new_item(
				loot["item_class"], randi_range(1, loot["amount"])
			)
			var random_x = randi_range(-Global.DROP_RANGE, Global.DROP_RANGE)
			var random_y = randi_range(-Global.DROP_RANGE, Global.DROP_RANGE)
			loot_item.position = position + Vector2(random_x, random_y)
			Global.level.items.add_child(loot_item)


func interact(_from: CharacterBody2D):
	pass


func add_item_to_loottable(item_class: String, drop_rate: float, amount: int = 1):
	loot_table.append({"item_class": item_class, "drop_rate": drop_rate, "amount": amount})


# Adding this line to be in line with players
func gain_experience(_amount: int):
	pass


func update_hp_bar():
	$Interface/HPBar.value = (hp * 100 / max_hp)


func _on_clock_attack_lock_timer_timeout():
	attacker = null
