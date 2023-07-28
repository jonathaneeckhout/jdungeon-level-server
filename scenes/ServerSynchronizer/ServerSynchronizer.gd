extends Node2D

var players_in_range = []
var is_player = false

@onready var root = $"../"


func _ready():
	#TODO: work with 2 areas to create a buffer zone
	$"NetworkSyncArea2D".body_entered.connect(_on_sync_area_body_entered)
	$"NetworkSyncArea2D".body_exited.connect(_on_sync_area_body_exited)


func _physics_process(_delta):
	var timestamp = Time.get_unix_time_from_system()

	if is_player:
		sync.rpc_id(root.player, timestamp, root.position)

	for other_player in players_in_range:
		sync.rpc_id(other_player.player, timestamp, root.position)


func _on_sync_area_body_entered(body):
	if body == root:
		return

	if is_player:
		LevelsConnection.add_player.rpc_id(root.player, body.player, body.name, body.position)

	else:
		LevelsConnection.add_enemy.rpc_id(body.player, root.name, root.CLASS, root.position)

	players_in_range.append(body)


func _on_sync_area_body_exited(body):
	if body == root:
		return

	if is_player:
		LevelsConnection.remove_player.rpc_id(root.player, body.name)
	else:
		if body.player in multiplayer.get_peers():
			LevelsConnection.remove_enemy.rpc_id(body.player, root.name)

	players_in_range.erase(body)


func sync_hurt(current_hp: int, amount: int):
	if is_player:
		hurt.rpc_id(root.player, current_hp, amount)

	for other_player in players_in_range:
		hurt.rpc_id(other_player.player, current_hp, amount)


func sync_attack(direction: Vector2):
	var timestamp = Time.get_unix_time_from_system()

	if is_player:
		attack.rpc_id(root.player, timestamp, direction)

	for other_player in players_in_range:
		attack.rpc_id(other_player.player, timestamp, direction)


func sync_experience(current_exp: int, amount: int, needed: int):
	var timestamp = Time.get_unix_time_from_system()

	if is_player:
		gain_experience.rpc_id(root.player, timestamp, current_exp, amount, needed)


func sync_level(current_level: int, amount: int):
	var timestamp = Time.get_unix_time_from_system()

	if is_player:
		gain_level.rpc_id(root.player, timestamp, current_level, amount)

	for other_player in players_in_range:
		gain_level.rpc_id(root.player, timestamp, current_level, amount)


@rpc("call_remote", "authority", "unreliable") func sync(
	_timestamp: float,
	_pos: Vector2,
):
	pass


@rpc("call_remote", "authority", "reliable") func hurt(_current_hp: int, _amount: int):
	pass


@rpc("call_remote", "authority", "reliable") func attack(_timestamp: int, _direction: Vector2):
	pass


@rpc("call_remote", "authority", "reliable") func gain_experience(
	_timestamp: int,
	_current_exp: int,
	_amount: int,
	_needed: int
):
	pass


@rpc("call_remote", "authority", "reliable")
func gain_level(_timestamp: int, _current_level: int, _amount: int):
	pass
