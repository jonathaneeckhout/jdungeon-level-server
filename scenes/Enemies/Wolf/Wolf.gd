extends CharacterBody2D

signal died

enum STATES { IDLE, WANDER, AGGROED, ATTACK }

const AGGRO_SPEED = 250.0
const WANDER_SPEED = 75.0
const ATTACK_SPEED = 1.0
const ATTACK_POWER = 5.0
const MAX_HP = 100.0

var state = STATES.IDLE
var hp = MAX_HP

var players_in_aggro_range = []
var players_in_attack_range = []

@onready var attack_timer = Timer.new()
@onready var server_synchronizer = $ServerSynchronizer


func _ready():
	#Handle server specific functionality
	if not multiplayer.is_server():
		return

	$AggroArea2D.body_entered.connect(_on_aggro_area_body_entered)
	$AggroArea2D.body_exited.connect(_on_aggro_area_body_exited)
	$AttackArea2D.body_entered.connect(_on_attack_area_body_entered)
	$AttackArea2D.body_exited.connect(_on_attack_area_body_exited)

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)


func _physics_process(delta):
	fsm(delta)

	move_and_slide()


func fsm(_delta):
	match state:
		STATES.IDLE:
			state = STATES.WANDER
			velocity = Vector2.ZERO
		STATES.WANDER:
			if players_in_attack_range.size() > 0:
				state = STATES.ATTACK
			elif players_in_aggro_range.size() > 0:
				state = STATES.AGGROED
			else:
				#TODO: implement wander behavior
				velocity = Vector2.ZERO
		STATES.AGGROED:
			if players_in_attack_range.size() > 0:
				state = STATES.ATTACK
			elif players_in_aggro_range.size() == 0:
				state = STATES.IDLE
			else:
				velocity = (
					(players_in_aggro_range[0].position - position).normalized() * AGGRO_SPEED
				)
		STATES.ATTACK:
			if players_in_attack_range.size() == 0:
				if players_in_aggro_range.size() > 0:
					state = STATES.AGGROED
				else:
					state = STATES.IDLE
			else:
				#TODO: implement attack behavior
				velocity = Vector2.ZERO

				if attack_timer.is_stopped():
					#TODO: implement smart aggro mechanism, for now just pick the first one
					attack(players_in_aggro_range[0])
					attack_timer.start(ATTACK_SPEED)


func attack(target: CharacterBody2D):
	target.hurt(ATTACK_POWER)


func hurt(damage: int):
	hp = max(0, hp - damage)

	if hp <= 0:
		died.emit()
		queue_free()
		return

	server_synchronizer.sync_hurt(hp, damage)
	update_hp_bar()


func update_hp_bar():
	$Interface/HPBar.value = (hp / MAX_HP) * 100


func _on_aggro_area_body_entered(body):
	if not players_in_aggro_range.has(body):
		players_in_aggro_range.append(body)


func _on_aggro_area_body_exited(body):
	if players_in_aggro_range.has(body):
		players_in_aggro_range.erase(body)


func _on_attack_area_body_entered(body):
	if not players_in_attack_range.has(body):
		players_in_attack_range.append(body)


func _on_attack_area_body_exited(body):
	if players_in_attack_range.has(body):
		players_in_attack_range.erase(body)


func _on_attack_timer_timeout():
	attack_timer.stop()