extends "res://scripts/entity.gd"

enum STATES { IDLE, WANDER, AGGROED, ATTACK }

const CLASS = "Wolf"
const AGGRO_SPEED = 250.0
const WANDER_SPEED = 75.0
const ATTACK_SPEED = 1.0

var state = STATES.IDLE

var players_in_aggro_range = []
var players_in_attack_range = []

@onready var attack_timer = Timer.new()


func _ready():
	super()

	$Interface/Name.text = CLASS

	$AggroArea2D.body_entered.connect(_on_aggro_area_body_entered)
	$AggroArea2D.body_exited.connect(_on_aggro_area_body_exited)
	$AttackArea2D.body_entered.connect(_on_attack_area_body_entered)
	$AttackArea2D.body_exited.connect(_on_attack_area_body_exited)

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)


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
				move_and_slide()
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
