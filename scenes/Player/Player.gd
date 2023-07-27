extends CharacterBody2D

enum STATES { IDLE, MOVE, ATTACK }

const SPEED = 300.0
const ATTACK_SPEED = 1.0
const ATTACK_POWER = 30.0
const MAX_HP = 100.0
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
var hp = MAX_HP
var state = STATES.IDLE
var enemies_in_attack_range = []

@onready var attack_timer = Timer.new()
@onready var save_timer = Timer.new()
# Player synchronized input.
@onready var input = $PlayerInput
@onready var server_synchronizer = $ServerSynchronizer


func _ready():
	input.move_target = position

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

	$AttackArea2D.body_entered.connect(_on_attack_area_body_entered)
	$AttackArea2D.body_exited.connect(_on_attack_area_body_exited)

	server_synchronizer.is_player = true

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
			#TODO: currently the only interaction is attacking
			elif input.interacting:
				state = STATES.ATTACK
			else:
				velocity = Vector2.ZERO
				state = STATES.IDLE
		STATES.MOVE:
			#TODO: currently the only interaction is attacking
			if input.interacting:
				state = STATES.ATTACK
			else:
				_handle_move()
		STATES.ATTACK:
			if input.moving:
				state = STATES.MOVE
			else:
				_handle_attack()


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


func _on_attack_timer_timeout():
	attack_timer.stop()


func attack(target: CharacterBody2D):
	target.hurt(ATTACK_POWER)
	server_synchronizer.sync_attack(position.direction_to(target.position))


func hurt(damage):
	# Deal damage if health pool is big enough
	if damage < hp:
		hp -= damage
		server_synchronizer.sync_hurt(hp, damage)
	# Die if damage is bigger than remaining hp
	else:
		die()

	update_hp_bar()


func die():
	var respawn_location = $"../../../../".find_player_respawn_location(position)
	#Stop doing what you were doing
	state = STATES.IDLE
	position = respawn_location
	hp = MAX_HP

	#TODO: sync dying, for now just update the hp again
	server_synchronizer.sync_hurt(hp, 0)


func update_hp_bar():
	$Interface/HPBar.value = (hp / MAX_HP) * 100


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


func _on_save_timer_timeout():
	CommonConnection.save_character(name, level, position)
