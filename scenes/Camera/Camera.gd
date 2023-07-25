extends Camera2D

const SPEED = 800


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position += input_direction * delta * SPEED
