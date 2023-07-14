extends Node2D

enum STATES { IDLE, MOVE, RUN }

const MIN_IDLE_TIME = 3
const MAX_IDLE_TIME = 10
const MAX_WANDER_DISTANCE = 256.0
const MOVE_SPEED = 75.0
const ARRIVAL_DISTANCE = 8
const RAY_SIZE = 64
const RAY_ANGLE = 30
const MAX_COLLIDING_TIME = 1.0

var state = STATES.IDLE
var starting_postion: Vector2
var wander_target: Vector2

@onready var root = $"../"

@onready var idle_timer = Timer.new()
@onready var colliding_timer = Timer.new()
@onready var rays = Node2D.new()
@onready var ray_direction = RayCast2D.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	starting_postion = root.position

	idle_timer.one_shot = true
	add_child(idle_timer)

	colliding_timer.one_shot = true
	add_child(colliding_timer)
	colliding_timer.timeout.connect(_on_colliding_timer_timeout)

	init_avoidance_rays()

	idle_timer.start(randi_range(MIN_IDLE_TIME, MAX_IDLE_TIME))

	ray_direction.target_position = Vector2(RAY_SIZE, 0)
	add_child(ray_direction)


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
		STATES.RUN:
			pass


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


func _on_colliding_timer_timeout():
	wander_target = find_random_spot(starting_postion, MAX_WANDER_DISTANCE)
