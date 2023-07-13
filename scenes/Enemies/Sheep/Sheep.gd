extends "res://scripts/entity.gd"

enum STATES { IDLE, MOVE, RUN }

const CLASS = "Sheep"
const MIN_IDLE_TIME = 3
const MAX_IDLE_TIME = 10
const MAX_WANDER_DISTANCE = 256
const MOVE_SPEED = 75.0
const ARRIVAL_DISTANCE = 8

var state = STATES.IDLE
var starting_postion: Vector2
var wander_target: Vector2

@onready var idle_timer = Timer.new()


func _ready():
	super()
	$Interface/Name.text = CLASS

	starting_postion = position

	idle_timer.one_shot = true
	add_child(idle_timer)
	idle_timer.start(randi_range(MIN_IDLE_TIME, MAX_IDLE_TIME))


func fsm(_delta):
	match state:
		STATES.IDLE:
			if idle_timer.is_stopped():
				state = STATES.MOVE
				find_random_spot()
		STATES.MOVE:
			_handle_move()
		STATES.RUN:
			pass


func find_random_spot():
	wander_target = Vector2(
		randi_range(
			starting_postion.x - MAX_WANDER_DISTANCE, starting_postion.x + MAX_WANDER_DISTANCE
		),
		randi_range(
			starting_postion.y - MAX_WANDER_DISTANCE, starting_postion.y + MAX_WANDER_DISTANCE
		)
	)


func _handle_move():
	if position.distance_to(wander_target) > ARRIVAL_DISTANCE:
		velocity = position.direction_to(wander_target) * MOVE_SPEED
		state = STATES.MOVE
	else:
		velocity = Vector2.ZERO
		state = STATES.IDLE
		idle_timer.start(randi_range(MIN_IDLE_TIME, MAX_IDLE_TIME))
