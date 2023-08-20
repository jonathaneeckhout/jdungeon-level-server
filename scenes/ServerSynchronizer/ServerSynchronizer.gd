extends Node2D

enum ENTITY_TYPES { PLAYER, ENEMY, ITEM, NPC }

var players_in_range = []
var is_player = false

var type = ENTITY_TYPES.ENEMY

@onready var root = $"../"


func _ready():
	#TODO: work with 2 areas to create a buffer zone
	$"NetworkSyncArea2D".body_entered.connect(_on_sync_area_body_entered)
	$"NetworkSyncArea2D".body_exited.connect(_on_sync_area_body_exited)


func _physics_process(_delta):
	# TODO: just disable the physics process for non moving entities
	if type != ENTITY_TYPES.PLAYER and type != ENTITY_TYPES.ENEMY and type != ENTITY_TYPES.NPC:
		return

	var timestamp = Time.get_unix_time_from_system()

	if type == ENTITY_TYPES.PLAYER:
		sync.rpc_id(root.player, timestamp, root.position)

	for other_player in players_in_range:
		sync.rpc_id(other_player.player, timestamp, root.position)


func _on_sync_area_body_entered(body):
	if body == root:
		return

	match type:
		ENTITY_TYPES.PLAYER:
			LevelsConnection.add_other_player.rpc_id(
				root.player, body.player, body.name, body.position, body.stats.hp, body.stats.max_hp
			)
		ENTITY_TYPES.ENEMY:
			LevelsConnection.add_enemy.rpc_id(
				body.player, root.name, root.CLASS, root.position, root.hp, root.max_hp
			)
		ENTITY_TYPES.ITEM:
			LevelsConnection.add_item.rpc_id(body.player, root.name, root.item.CLASS, root.position)
		ENTITY_TYPES.NPC:
			LevelsConnection.add_npc.rpc_id(
				body.player, root.name, root.CLASS, root.position, root.hp, root.max_hp
			)

	players_in_range.append(body)


func _on_sync_area_body_exited(body):
	if body == root:
		return

	if multiplayer.multiplayer_peer != null:
		match type:
			ENTITY_TYPES.PLAYER:
				if root.player in multiplayer.get_peers():
					LevelsConnection.remove_other_player.rpc_id(root.player, body.name)
			ENTITY_TYPES.ENEMY:
				if body.player in multiplayer.get_peers():
					LevelsConnection.remove_enemy.rpc_id(body.player, root.name)
			ENTITY_TYPES.ITEM:
				if body.player in multiplayer.get_peers():
					LevelsConnection.remove_item.rpc_id(body.player, root.name)
			ENTITY_TYPES.NPC:
				if body.player in multiplayer.get_peers():
					LevelsConnection.remove_npc.rpc_id(body.player, root.name)

	players_in_range.erase(body)


func sync_hurt(current_hp: int, amount: int):
	# Only valid for players and enemies
	if type != ENTITY_TYPES.PLAYER and type != ENTITY_TYPES.ENEMY:
		return

	if type == ENTITY_TYPES.PLAYER:
		hurt.rpc_id(root.player, current_hp, amount)

	for other_player in players_in_range:
		hurt.rpc_id(other_player.player, current_hp, amount)


func sync_heal(current_hp: int, amount: int):
	# Only valid for players and enemies
	if type != ENTITY_TYPES.PLAYER and type != ENTITY_TYPES.ENEMY:
		return

	if type == ENTITY_TYPES.PLAYER:
		heal.rpc_id(root.player, current_hp, amount)

	for other_player in players_in_range:
		heal.rpc_id(other_player.player, current_hp, amount)


func sync_attack(direction: Vector2):
	# Only valid for players and enemies
	if type != ENTITY_TYPES.PLAYER and type != ENTITY_TYPES.ENEMY:
		return

	var timestamp = Time.get_unix_time_from_system()

	if type == ENTITY_TYPES.PLAYER:
		attack.rpc_id(root.player, timestamp, direction)

	for other_player in players_in_range:
		attack.rpc_id(other_player.player, timestamp, direction)


func sync_experience(current_exp: int, amount: int):
	# Only valid for players
	if type != ENTITY_TYPES.PLAYER:
		return

	var timestamp = Time.get_unix_time_from_system()

	gain_experience.rpc_id(root.player, timestamp, current_exp, amount)


func sync_level(current_level: int, amount: int, exp_needed_for_next_level: int):
	# Only valid for players
	if type != ENTITY_TYPES.PLAYER:
		return

	var timestamp = Time.get_unix_time_from_system()

	gain_level.rpc_id(root.player, timestamp, current_level, amount, exp_needed_for_next_level)

	for other_player in players_in_range:
		gain_level.rpc_id(root.player, timestamp, current_level, amount, exp_needed_for_next_level)


@rpc("call_remote", "authority", "unreliable") func sync(
	_timestamp: float,
	_pos: Vector2,
):
	pass


@rpc("call_remote", "authority", "reliable") func hurt(_current_hp: int, _amount: int):
	pass


@rpc("call_remote", "authority", "reliable") func heal(_current_hp: int, _amount: int):
	pass


@rpc("call_remote", "authority", "reliable") func attack(_timestamp: int, _direction: Vector2):
	pass


@rpc("call_remote", "authority", "reliable")
func gain_experience(_timestamp: int, _current_exp: int, _amount: int):
	pass


@rpc("call_remote", "authority", "reliable") func gain_level(
	_timestamp: int, _current_level: int, _amount: int, _exp_needed_for_next_level: int
):
	pass
