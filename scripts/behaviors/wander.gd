extends Node2D

enum STATES { IDLE, MOVE, FLEE, AGGROED, ATTACK }

const MIN_IDLE_TIME = 3
const MAX_IDLE_TIME = 10
const MAX_WANDER_DISTANCE = 256.0
const MOVE_SPEED = 75.0
const FLEE_SPEED = 150.0
const ARRIVAL_DISTANCE = 8
const RAY_SIZE = 64
const RAY_ANGLE = 30
const MAX_COLLIDING_TIME = 1.0
const AGGRO_SPEED = 250.0
const WANDER_SPEED = 75.0
const ATTACK_SPEED = 1.0

var state = STATES.IDLE
var starting_postion: Vector2
var wander_target: Vector2

var players_in_aggro_range = []
var players_in_attack_range = []
var attackers_in_aggro_range = []

@onready var root = $"../"

@onready var idle_timer = Timer.new()
@onready var colliding_timer = Timer.new()
@onready var attack_timer = Timer.new()
@onready var rays = Node2D.new()
@onready var ray_direction = RayCast2D.new()


func _ready():
	name = "BehaviorNode"


func init_wander():
	starting_postion = root.position

	idle_timer.one_shot = true
	idle_timer.name = "IdleTimer"
	add_child(idle_timer)

	colliding_timer.one_shot = true
	colliding_timer.name = "CollidingTimer"
	add_child(colliding_timer)
	colliding_timer.timeout.connect(_on_colliding_timer_timeout)

	init_avoidance_rays()

	idle_timer.start(randi_range(MIN_IDLE_TIME, MAX_IDLE_TIME))

	ray_direction.target_position = Vector2(RAY_SIZE, 0)
	add_child(ray_direction)


func init_wander_and_flee():
	init_wander()

	var flee_area = Area2D.new()
	flee_area.name = "FleeArea2D"
	flee_area.collision_layer = 0
	flee_area.collision_mask = 2

	var cs_flee_area = CollisionShape2D.new()
	flee_area.add_child(cs_flee_area)

	var cs_flee_circle = CircleShape2D.new()

	cs_flee_circle.radius = 512.0
	cs_flee_area.shape = cs_flee_circle

	add_child(flee_area)

	flee_area.body_entered.connect(_on_flee_area_body_entered)
	flee_area.body_exited.connect(_on_flee_area_body_exited)


func init_wander_and_attack():
	init_wander()

	var aggro_area = Area2D.new()
	aggro_area.name = "AggroArea2D"
	aggro_area.collision_layer = 0
	aggro_area.collision_mask = 2

	var cs_aggro_area = CollisionShape2D.new()
	aggro_area.add_child(cs_aggro_area)

	var cs_aggro_circle = CircleShape2D.new()

	cs_aggro_circle.radius = 256.0
	cs_aggro_area.shape = cs_aggro_circle

	add_child(aggro_area)

	aggro_area.body_entered.connect(_on_aggro_area_body_entered)
	aggro_area.body_exited.connect(_on_aggro_area_body_exited)

	var attack_area = Area2D.new()
	attack_area.name = "AttackArea2D"
	attack_area.collision_layer = 0
	attack_area.collision_mask = 2

	var cs_attack_area = CollisionShape2D.new()
	attack_area.add_child(cs_attack_area)

	var cs_attack_circle = CircleShape2D.new()

	cs_attack_circle.radius = 64.0
	cs_attack_area.shape = cs_attack_circle

	add_child(attack_area)

	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.name = "AttackTimer"
	add_child(attack_timer)


func init_avoidance_rays():
	rays.name = "Rays"

	var ray_front = RayCast2D.new()
	var ray_left_0 = RayCast2D.new()
	var ray_left_1 = RayCast2D.new()
	var ray_right_0 = RayCast2D.new()
	var ray_right_1 = RayCast2D.new()

	ray_front.enabled = true
	ray_left_0.enabled = true
	ray_left_1.enabled = true
	ray_right_0.enabled = true
	ray_right_1.enabled = true

	ray_front.name = "FrontRay"
	ray_left_0.name = "LeftRay0"
	ray_left_1.name = "LeftRay1"
	ray_right_0.name = "RightRay0"
	ray_right_1.name = "RightRay1"

	ray_front.target_position = Vector2(RAY_SIZE, 0)
	ray_left_0.target_position = Vector2(RAY_SIZE / 1.5, 0)
	ray_left_1.target_position = Vector2(RAY_SIZE / 2.0, 0)
	ray_right_0.target_position = Vector2(RAY_SIZE / 1.5, 0)
	ray_right_1.target_position = Vector2(RAY_SIZE / 2.0, 0)

	ray_left_0.rotation_degrees = -(1 * RAY_ANGLE)
	ray_left_1.rotation_degrees = -(2 * RAY_ANGLE)
	ray_right_0.rotation_degrees = 1 * RAY_ANGLE
	ray_right_1.rotation_degrees = 2 * RAY_ANGLE

	rays.add_child(ray_left_0)
	rays.add_child(ray_right_0)
	rays.add_child(ray_left_1)
	rays.add_child(ray_right_1)
	rays.add_child(ray_front)

	# rays.visible = false

	add_child(rays)


func fsm_wander(_delta):
	match state:
		STATES.IDLE:
			if idle_timer.is_stopped():
				state = STATES.MOVE
				wander_target = find_random_spot(starting_postion, MAX_WANDER_DISTANCE)
		STATES.MOVE:
			_handle_move()


func fsm_wander_and_flee(_delta):
	match state:
		STATES.IDLE:
			if root.attacker:
				state = STATES.FLEE
			elif idle_timer.is_stopped():
				state = STATES.MOVE
				wander_target = find_random_spot(starting_postion, MAX_WANDER_DISTANCE)
		STATES.MOVE:
			if root.attacker:
				state = STATES.FLEE
			else:
				_handle_move()
		STATES.FLEE:
			if not root.attacker or not is_instance_valid(root.attacker):
				state = STATES.IDLE
			else:
				_handle_flee()


func fsm_wander_and_attack(_delta):
	match state:
		STATES.IDLE:
			if players_in_aggro_range.size() > 0:
				state = STATES.AGGROED
			elif idle_timer.is_stopped():
				state = STATES.MOVE
				wander_target = find_random_spot(starting_postion, MAX_WANDER_DISTANCE)
		STATES.MOVE:
			if players_in_aggro_range.size() > 0:
				state = STATES.AGGROED
			else:
				_handle_move()
		STATES.AGGROED:
			if players_in_attack_range.size() > 0:
				state = STATES.ATTACK
			elif players_in_aggro_range.size() == 0:
				state = STATES.IDLE
			else:
				root.velocity = (
					(players_in_aggro_range[0].position - root.position).normalized() * AGGRO_SPEED
				)
				root.move_and_slide()
		STATES.ATTACK:
			if players_in_attack_range.size() == 0:
				if players_in_aggro_range.size() > 0:
					state = STATES.AGGROED
				else:
					state = STATES.IDLE
			else:
				#TODO: implement attack behavior
				root.velocity = Vector2.ZERO

				if attack_timer.is_stopped():
					#TODO: implement smart aggro mechanism, for now just pick the first one
					root.attack(players_in_aggro_range[0])
					attack_timer.start(ATTACK_SPEED)


func find_random_spot(origin: Vector2, distance: float) -> Vector2:
	return Vector2(
		float(randi_range(origin.x - distance, origin.x + distance)),
		float(randi_range(origin.y - distance, origin.y + distance))
	)


func _handle_move():
	if root.position.distance_to(wander_target) > ARRIVAL_DISTANCE:
		root.velocity = root.position.direction_to(wander_target) * MOVE_SPEED
		_move_with_avoidance()
		if root.get_slide_collision_count() > 0:
			if colliding_timer.is_stopped():
				colliding_timer.start(MAX_COLLIDING_TIME)
		else:
			if !colliding_timer.is_stopped():
				colliding_timer.stop()
		ray_direction.rotation = root.velocity.angle()
		state = STATES.MOVE
	else:
		root.velocity = Vector2.ZERO
		state = STATES.IDLE
		idle_timer.start(randi_range(MIN_IDLE_TIME, MAX_IDLE_TIME))


func _handle_flee():
	if root.attacker in attackers_in_aggro_range:
		root.velocity = root.attacker.position.direction_to(root.position) * FLEE_SPEED
		_move_with_avoidance()
	else:
		root.velocity = Vector2.ZERO
		_move_with_avoidance()


func _move_with_avoidance():
	rays.rotation = root.velocity.angle()
	if _obstacle_ahead():
		var viable_ray = _get_viable_ray()
		if viable_ray:
			root.velocity = Vector2.RIGHT.rotated(rays.rotation + viable_ray.rotation) * MOVE_SPEED
			root.move_and_slide()
	else:
		root.move_and_slide()


func _obstacle_ahead() -> bool:
	for ray in rays.get_children():
		if ray.is_colliding():
			return true

	return false


func _get_viable_ray() -> RayCast2D:
	for ray in rays.get_children():
		if !ray.is_colliding():
			return ray
	return null


func _on_aggro_area_body_entered(body):
	if not players_in_aggro_range.has(body):
		players_in_aggro_range.append(body)


func _on_aggro_area_body_exited(body):
	if players_in_aggro_range.has(body):
		players_in_aggro_range.erase(body)


func _on_flee_area_body_entered(body):
	if not attackers_in_aggro_range.has(body):
		attackers_in_aggro_range.append(body)


func _on_flee_area_body_exited(body):
	if attackers_in_aggro_range.has(body):
		attackers_in_aggro_range.erase(body)


func _on_attack_area_body_entered(body):
	if not players_in_attack_range.has(body):
		players_in_attack_range.append(body)


func _on_attack_area_body_exited(body):
	if players_in_attack_range.has(body):
		players_in_attack_range.erase(body)


func _on_attack_timer_timeout():
	attack_timer.stop()


func _on_colliding_timer_timeout():
	wander_target = find_random_spot(starting_postion, MAX_WANDER_DISTANCE)
