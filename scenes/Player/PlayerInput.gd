extends MultiplayerSynchronizer

@export var moving := false
@export var move_target := Vector2()

@export var interacting := false
var interact_target = ""

@rpc("call_local", "any_peer", "reliable")
func move(position):
	moving = true
	move_target = position


@rpc("call_local", "any_peer", "reliable")
func interact(target: String):
	if $"../../../Enemies".has_node(target):
		interacting = true
		interact_target = $"../../../Enemies".get_node(target)


func reset_inputs():
	moving = false
	interacting = false