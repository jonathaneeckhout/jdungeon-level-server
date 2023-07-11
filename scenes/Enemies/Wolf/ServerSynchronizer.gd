extends Node2D

var players_in_range = []

@onready var enemy = $"../"


func _ready():
	#TODO: work with 2 areas to create a buffer zone
	$"NetworkSyncArea2D".body_entered.connect(_on_sync_area_body_entered)
	$"NetworkSyncArea2D".body_exited.connect(_on_sync_area_body_exited)


func _process(_delta):
	var timestamp = Time.get_unix_time_from_system()
	for other_player in players_in_range:
		sync.rpc_id(other_player.player, timestamp, enemy.position)


func _on_sync_area_body_entered(body):
	if body == enemy:
		return

	LevelsConnection.add_enemy.rpc_id(body.player, enemy.name, enemy.position)
	players_in_range.append(body)


func _on_sync_area_body_exited(body):
	if body == enemy:
		return

	LevelsConnection.remove_enemy.rpc_id(body.player, enemy.name)
	players_in_range.erase(body)


func sync_hurt(current_hp: int, amount: int):
	for other_player in players_in_range:
		hurt.rpc_id(other_player.player, current_hp, amount)


@rpc("call_remote", "authority", "unreliable") func sync(
	_timestamp: float,
	_pos: Vector2,
):
	pass


@rpc("call_remote", "authority", "reliable") func hurt(_current_hp: int, _amount: int):
	pass
