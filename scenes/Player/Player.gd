extends CharacterBody2D

@export var username := "":
	set(user):
		username = user
		$Interface/Username.text = username

@export var vel: Vector2


var minSpeed: float = 50.0
var maxSpeed: float = 100.0
var areaRect: Rect2 = Rect2(-200, -200, 400, 400)
var targetPosition: Vector2 = position


func _ready():
	randomize()
	set_process(true)
	areaRect.position = position


func _process(delta: float):
	if position.distance_to(targetPosition) < 10.0:
		choose_new_target_position()
	velocity = velocity.move_toward(targetPosition - position, maxSpeed * delta)
	move_and_slide()
	vel = velocity


func choose_new_target_position():
	targetPosition = Vector2(
		randf_range(areaRect.position.x, areaRect.position.x + areaRect.size.x),
		randf_range(areaRect.position.y, areaRect.position.y + areaRect.size.y)
	)


func clamp_position():
	position.x = clamp(position.x, areaRect.position.x, areaRect.position.x + areaRect.size.x)
	position.y = clamp(position.y, areaRect.position.y, areaRect.position.y + areaRect.size.y)
