extends Node2D

const SYNC_SPEED = 0.25

@onready var sync_timer = Timer.new()
@onready var player = $"../"

var players_in_range = []

func _ready():
	sync_timer.timeout.connect(_on_sync_timer_timeout)
	add_child(sync_timer)
	#TODO: not sure if syncing can start immediately or need to wait for comfirmation of client
	sync_timer.start(SYNC_SPEED)

	#TODO: work with 2 areas to create a buffer zone
	$"NetworkSyncArea2D".body_entered.connect(_on_sync_area_body_entered)
	$"NetworkSyncArea2D".body_exited.connect(_on_sync_area_body_exited)


func _on_sync_timer_timeout():
	sync.rpc_id(player.player, player.position, player.velocity)
	for other_player in players_in_range:
		sync.rpc_id(other_player.player, player.position, player.velocity)


func _on_sync_area_body_entered(body):
	if body == player:
		return

	LevelsConnection.add_player.rpc_id(player.player, body.player, body.name, body.position)
	players_in_range.append(body)


func _on_sync_area_body_exited(body):
	if body == player:
		return

	LevelsConnection.remove_player.rpc_id(player.player, body.name)
	players_in_range.erase(body)


func sync_hurt(current_hp: int, amount: int):
	hurt.rpc_id(player.player, current_hp, amount)
	for other_player in players_in_range:
		hurt.rpc_id(player.player, current_hp, amount)


@rpc("call_remote", "authority", "unreliable")
func sync(_pos, _vel):
	pass


@rpc("call_remote", "authority", "reliable")
func hurt(_current_hp: int, _amount: int):
	pass