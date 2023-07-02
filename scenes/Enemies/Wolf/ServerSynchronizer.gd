extends Node2D

const SYNC_SPEED = 0.25

@onready var sync_timer = Timer.new()
@onready var enemy = $"../"

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
	for other_player in players_in_range:
		sync.rpc_id(other_player.player, enemy.position, enemy.velocity)


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


@rpc("call_remote", "authority", "unreliable")
func sync(_pos, _vel):
	pass
