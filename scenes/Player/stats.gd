extends Node

const BASE_EXPERIENCE = 100

var level: int = 1
var experience: int = 0

var experience_needed_for_next_level = BASE_EXPERIENCE

@onready var server_synchronizer = $"../ServerSynchronizer"


# Called when the node enters the scene tree for the first time.
func _ready():
	experience_needed_for_next_level = calculate_experience_needed_next_level(level)
	server_synchronizer.sync_level(level, 0)
	server_synchronizer.sync_experience(experience, 0)


func calculate_experience_needed_next_level(current_level: int):
	return BASE_EXPERIENCE + (BASE_EXPERIENCE * (pow(current_level, 2) - 1))


func add_level(amount: int):
	level += amount
	experience_needed_for_next_level = calculate_experience_needed_next_level(level)
	server_synchronizer.sync_level(level, amount)


func add_experience(amount: int):
	experience += amount

	# print("Current experience %d" % experience)
	while experience >= experience_needed_for_next_level:
		experience -= experience_needed_for_next_level
		add_level(1)

	server_synchronizer.sync_experience(experience, amount)
