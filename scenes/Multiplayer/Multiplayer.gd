extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	# Add camera when running not runnig headless
	if not DisplayServer.get_name() == "headless":
		var camera_scene = load("res://scenes/Camera/Camera.tscn")
		var camera = camera_scene.instantiate()
		add_child(camera)
