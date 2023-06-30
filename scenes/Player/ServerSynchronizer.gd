extends Node

const SYNC_SPEED = 0.25

@onready var sync_timer = Timer.new()
@onready var player = $"../"

func _ready():
	sync_timer.timeout.connect(_on_sync_timer_timeout)
	add_child(sync_timer)
	#TODO: not sure if syncing can start immediately or need to wait for comfirmation of client
	sync_timer.start(SYNC_SPEED)


func _on_sync_timer_timeout():
	sync.rpc_id(player.player, player.position, player.velocity)


@rpc("call_remote", "authority", "unreliable")
func sync(_pos, _vel):
	pass
