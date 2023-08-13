extends Node

const BASE_EXPERIENCE = 100
const BASE_ATTACK_POWER = 1
const BASE_ATTACK_SPEED = 1.0

var max_hp: int = 10
var hp: int = max_hp

var level: int = 1
var experience: int = 0

var experience_needed_for_next_level = BASE_EXPERIENCE

var attack_power: int = BASE_ATTACK_POWER
var attack_speed: float = BASE_ATTACK_SPEED
var defense: int = 0

@onready var root = $".."
@onready var server_synchronizer = $"../ServerSynchronizer"


func _ready():
	LevelsConnection.player_requested_stats.connect(_on_player_requested_stats)

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


func update_stats():
	update_attack_power()


func update_attack_power():
	attack_power = int(BASE_ATTACK_POWER + (BASE_ATTACK_POWER * level / 10))


func get_output():
	var output = {
		"stats":
		{
			"level": level,
			"experience": experience,
			"hp": hp,
			"max_hp": max_hp,
			"experience_needed": experience_needed_for_next_level,
			"attack_power": attack_power,
			"attack_speed": attack_speed,
			"defense": defense
		}
	}

	return output


func _on_player_requested_stats(id: int):
	if root.player != id:
		return

	LevelsConnection.sync_stats.rpc_id(id, get_output())
