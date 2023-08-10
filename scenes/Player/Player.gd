extends CharacterBody2D

enum STATES { IDLE, MOVE, ATTACK, LOOT, NPC }

const SPEED = 300.0
const ATTACK_SPEED = 1.0
const ATTACK_POWER = 30.0
const ARRIVAL_DISTANCE = 8
const SAVE_INTERVAL_TIME = 300.0

@export var username := "":
	set(user):
		username = user
		$Interface/Username.text = username

# Set by the authority, synchronized on spawn.
@export var player := 1:
	set(id):
		player = id
		# Give authority over the player input to the appropriate peer.
		$PlayerInput.set_multiplayer_authority(id)

@export var vel: Vector2

var level: String = ""
var state = STATES.IDLE
var enemies_in_attack_range = []
var bodies_in_interact_range = []
var stats: Node = load("res://scenes/Player/stats.gd").new()
var inventory: Node = load("res://scenes/Player/inventory.gd").new()
var equipment: Node = load("res://scenes/Player/equipment.gd").new()

@onready var attack_timer = Timer.new()
@onready var save_timer = Timer.new()
# Player synchronized input.
@onready var input = $PlayerInput
@onready var server_synchronizer = $ServerSynchronizer


func _ready():
	add_child(stats)
	add_child(inventory)
	add_child(equipment)

	input.move_target = position

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

	$AttackArea2D.body_entered.connect(_on_attack_area_body_entered)
	$AttackArea2D.body_exited.connect(_on_attack_area_body_exited)

	$InteractArea2D.body_entered.connect(_on_interact_area_body_entered)
	$InteractArea2D.body_exited.connect(_on_interact_area_body_exited)

	server_synchronizer.type = server_synchronizer.ENTITY_TYPES.PLAYER

	save_timer.wait_time = SAVE_INTERVAL_TIME
	save_timer.autostart = true
	save_timer.timeout.connect(_on_save_timer_timeout)
	add_child(save_timer)


func _physics_process(delta):
	#Player's behavior is determined on server side
	if multiplayer.is_server():
		fsm(delta)
		input.reset_inputs()

	move_and_slide()
	vel = velocity


func fsm(_delta):
	match state:
		STATES.IDLE:
			if input.moving:
				state = STATES.MOVE
			elif input.interacting:
				_handle_interact_input()
			else:
				velocity = Vector2.ZERO
				state = STATES.IDLE
		STATES.MOVE:
			if input.interacting:
				_handle_interact_input()
			else:
				_handle_move()
		STATES.ATTACK:
			if input.moving:
				state = STATES.MOVE
			elif input.interacting:
				_handle_interact_input()
			else:
				_handle_attack()
		STATES.LOOT:
			if input.moving:
				state = STATES.MOVE
			elif input.interacting:
				_handle_interact_input()
			else:
				_handle_loot()
		STATES.NPC:
			if input.moving:
				state = STATES.MOVE
			elif input.interacting:
				_handle_interact_input()
			else:
				_handle_npc()


func _handle_interact_input():
	match input.interact_type:
		input.INTERACT_TYPES.ENEMY:
			state = STATES.ATTACK
		input.INTERACT_TYPES.NPC:
			state = STATES.NPC
		input.INTERACT_TYPES.ITEM:
			state = STATES.LOOT


func _handle_attack():
	if not is_instance_valid(input.interact_target):
		state = STATES.IDLE
		return

	if not enemies_in_attack_range.has(input.interact_target):
		velocity = position.direction_to(input.interact_target.position) * SPEED
	else:
		velocity = Vector2.ZERO

		if attack_timer.is_stopped():
			attack(input.interact_target)
			attack_timer.start(ATTACK_SPEED)

	state = STATES.ATTACK


func _handle_loot():
	if not is_instance_valid(input.interact_target):
		state = STATES.IDLE
		return

	if not bodies_in_interact_range.has(input.interact_target):
		velocity = position.direction_to(input.interact_target.position) * SPEED
		state = STATES.LOOT
	else:
		velocity = Vector2.ZERO

		input.interact_target.interact(self)
		state = STATES.IDLE


func _handle_npc():
	if not is_instance_valid(input.interact_target):
		state = STATES.IDLE
		return

	if not bodies_in_interact_range.has(input.interact_target):
		velocity = position.direction_to(input.interact_target.position) * SPEED
		state = STATES.NPC
	else:
		velocity = Vector2.ZERO

		input.interact_target.interact(self)
		state = STATES.IDLE


func attack(target: CharacterBody2D):
	target.hurt(self, ATTACK_POWER)
	server_synchronizer.sync_attack(position.direction_to(target.position))


func hurt(damage):
	# Deal damage if health pool is big enough
	if damage < stats.hp:
		stats.hp -= damage
		server_synchronizer.sync_hurt(stats.hp, damage)
	# Die if damage is bigger than remaining hp
	else:
		die()

	update_hp_bar()


func heal(healing):
	stats.hp = min(stats.hp + healing, stats.max_hp)
	server_synchronizer.sync_heal(stats.hp, healing)
	update_hp_bar()


func die():
	var respawn_location = $"../../../../".find_player_respawn_location(position)
	#Stop doing what you were doing
	state = STATES.IDLE
	position = respawn_location
	stats.hp = stats.max_hp

	#TODO: sync dying, for now just update the hp again
	server_synchronizer.sync_hurt(stats.hp, 0)


func equip_item(item: Item):
	return equipment.equip_item(item)


func update_hp_bar():
	$Interface/HPBar.value = (stats.hp / stats.max_hp) * 100


func gain_experience(amount: int):
	stats.add_experience(amount)


func _handle_move():
	if position.distance_to(input.move_target) > ARRIVAL_DISTANCE:
		velocity = position.direction_to(input.move_target) * SPEED
		state = STATES.MOVE
	else:
		velocity = Vector2.ZERO
		state = STATES.IDLE


func _on_attack_area_body_entered(body):
	if not enemies_in_attack_range.has(body):
		enemies_in_attack_range.append(body)


func _on_attack_area_body_exited(body):
	if enemies_in_attack_range.has(body):
		enemies_in_attack_range.erase(body)


func _on_interact_area_body_entered(body):
	if not bodies_in_interact_range.has(body):
		bodies_in_interact_range.append(body)


func _on_interact_area_body_exited(body):
	if bodies_in_interact_range.has(body):
		bodies_in_interact_range.erase(body)


func _on_attack_timer_timeout():
	attack_timer.stop()


func _on_save_timer_timeout():
	CommonConnection.save_character(
		name, level, position, inventory.gold, inventory.get_output(), equipment.get_output()
	)
