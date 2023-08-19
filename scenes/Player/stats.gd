extends Node

const BASE_EXPERIENCE = 100
const BASE_MAX_HP = 10
const BASE_ATTACK_POWER = 1
const BASE_ATTACK_SPEED = 1.0
const BASE_DEFENSE = 0

var max_hp: int = 10
var hp: int = max_hp

var level: int = 1
var experience: int = 0

var experience_needed_for_next_level = BASE_EXPERIENCE

var attack_power: int = BASE_ATTACK_POWER:
	set(value):
		attack_power = value
		min_attack_power = int((attack_power * 60) / 100)

var min_attack_power: int = 0

var attack_speed: float = BASE_ATTACK_SPEED
var defense: int = 0

@onready var root = $".."
@onready var server_synchronizer = $"../ServerSynchronizer"


func _ready():
	LevelsConnection.player_requested_stats.connect(_on_player_requested_stats)

	root.equipment.equipment_changed.connect(_on_equipment_changed)

	update_stats()

	experience_needed_for_next_level = calculate_experience_needed_next_level(level)

	server_synchronizer.sync_level(level, 0, experience_needed_for_next_level)
	server_synchronizer.sync_experience(experience, 0)


func calculate_experience_needed_next_level(current_level: int):
	return BASE_EXPERIENCE + (BASE_EXPERIENCE * (pow(current_level, 2) - 1))


func add_level(amount: int):
	level += amount
	experience_needed_for_next_level = calculate_experience_needed_next_level(level)
	server_synchronizer.sync_level(level, amount, experience_needed_for_next_level)


func add_experience(amount: int):
	experience += amount

	# print("Current experience %d" % experience)
	while experience >= experience_needed_for_next_level:
		experience -= experience_needed_for_next_level
		add_level(1)

	server_synchronizer.sync_experience(experience, amount)


func update_stats():
	var equipment_stats = root.equipment.get_stats()
	update_max_hp(equipment_stats)
	update_attack_power(equipment_stats)
	update_attack_speed(equipment_stats)
	update_defense(equipment_stats)

	LevelsConnection.sync_stats.rpc_id(root.player, get_output())


func update_max_hp(_equipment_stats: Dictionary):
	max_hp = int(BASE_MAX_HP + (BASE_MAX_HP * level / 2))

	root.update_hp_bar()


func update_attack_power(equipment_stats: Dictionary):
	attack_power = int(BASE_ATTACK_POWER + (BASE_ATTACK_POWER * level / 10))

	if equipment_stats.has("attack_power"):
		attack_power += equipment_stats["attack_power"]


func update_attack_speed(equipment_stats: Dictionary):
	attack_speed = BASE_ATTACK_SPEED
	if equipment_stats.has("attack_speed"):
		if equipment_stats["attack_speed"] > 0:
			attack_speed = equipment_stats["attack_speed"]


func update_defense(equipment_stats: Dictionary):
	defense = int(BASE_DEFENSE + (BASE_DEFENSE * level / 10))

	if equipment_stats.has("defense"):
		defense += equipment_stats["defense"]


func get_output():
	var output = {
		"level": level,
		"experience": experience,
		"hp": hp,
		"max_hp": max_hp,
		"experience_needed": experience_needed_for_next_level,
		"attack_power": attack_power,
		"attack_speed": attack_speed,
		"defense": defense
	}

	return output


func load_stats(stats_data: Dictionary):
	level = stats_data.get("level", 1)
	experience = stats_data.get("experience", 0)
	hp = stats_data.get("hp", max_hp)


func _on_player_requested_stats(id: int):
	if root.player != id:
		return

	LevelsConnection.sync_stats.rpc_id(id, get_output())


func _on_equipment_changed():
	update_stats()
