extends Node

const BASE_EXPERIENCE = 100

@export var level: int = 1:
	set(value):
		server_synchronizer.sync_level(value, value - level)

		level = value
		experience_needed_for_next_level += calculate_experience_needed_next_level(level)
		# print("Current level %d" % level)
		# print("Experience needed %d" % experience_needed_for_next_level)

@export var experience: int = 0:
	set(value):
		server_synchronizer.sync_experience(
			value, value - experience, experience_needed_for_next_level
		)

		experience = value
		# print("Current experience %d" % experience)
		while experience >= experience_needed_for_next_level:
			experience -= experience_needed_for_next_level
			level += 1

var experience_needed_for_next_level = BASE_EXPERIENCE

@onready var server_synchronizer = $"../ServerSynchronizer"


# Called when the node enters the scene tree for the first time.
func _ready():
	experience_needed_for_next_level = calculate_experience_needed_next_level(level)


func calculate_experience_needed_next_level(current_level: int):
	return BASE_EXPERIENCE + (BASE_EXPERIENCE * (pow(current_level, 2) - 1))
