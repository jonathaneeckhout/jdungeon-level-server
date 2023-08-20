extends Node

enum STATES { INIT, AUTHENTICATE, DISCONNECTED, RUNNING }

const AUTH_RETRY_TIME = 10.0

var state: STATES = STATES.INIT

var fsm_timer: Timer
var auth_retry_timer: Timer


func _ready():
	CommonConnection.disconnected.connect(_on_common_server_disconnected)

	# Add a short timer to deffer the fsm() calls
	fsm_timer = Timer.new()
	fsm_timer.wait_time = 0.1
	fsm_timer.autostart = false
	fsm_timer.one_shot = true
	fsm_timer.timeout.connect(_on_fsm_timer_timeout)
	add_child(fsm_timer)

	# Add a retry timer for when the authentication failed or we got disconnected
	auth_retry_timer = Timer.new()
	auth_retry_timer.wait_time = AUTH_RETRY_TIME
	auth_retry_timer.autostart = false
	auth_retry_timer.one_shot = true
	auth_retry_timer.timeout.connect(_on_auth_retry_timer_timeout)
	add_child(auth_retry_timer)

	fsm_timer.start()


func fsm():
	match state:
		STATES.INIT:
			_handle_init()
		STATES.AUTHENTICATE:
			_handle_authenticate()
		STATES.DISCONNECTED:
			_handle_disconnected()
		STATES.RUNNING:
			_handle_running()


func _handle_init():
	# Load the environment variables
	if not Global.load_env_variables():
		print("FSM: Failed to load environment variables, quitting server")
		get_tree().quit()
		return

	# Load the level depending on the "LEVEL" environment variable
	if not await Global.level.set_level(Global.env_level):
		print("FSM: Failed to load level=[%s], quitting server" % Global.env_level)
		get_tree().quit()
		return

	print("FSM: Init done")
	state = STATES.AUTHENTICATE

	fsm_timer.start()


func _handle_authenticate():
	# Try to authenticate to the common server
	if not await CommonConnection.authenticate():
		print("FSM: Failed to authenticate to common server")
		# Start the retry timer when authentication failed
		auth_retry_timer.start()
		return

	# Start the ping timer to keep an eye on the connection status
	CommonConnection.start_ping_timer()
	# Start the authentication timer to keep a valid cookie
	CommonConnection.start_authentication_timer()

	# Upload the level information to the server
	await CommonConnection.upload_level_info(Global.env_level, Global.level.get_info())

	# Start the level server
	LevelsConnection.start()

	print("FSM: Authentication with common server done")
	state = STATES.RUNNING

	fsm_timer.start()


func _handle_disconnected():
	# Stop the level server as the service can not be guaranteed
	LevelsConnection.stop()

	# Stop the ping timer if disconnected
	CommonConnection.stop_ping_timer()
	# Stop the authentication timer if disconnected
	CommonConnection.stop_authentication_timer()

	# Fall back to the authentication state to retry to connect/authenticate
	state = STATES.AUTHENTICATE
	auth_retry_timer.start()


func _handle_running():
	pass


func _on_fsm_timer_timeout():
	fsm()


func _on_auth_retry_timer_timeout():
	print("FSM: Retrying to authenticate to common server")
	fsm()


func _on_common_server_disconnected():
	print("FSM: Got disconnected from common server")

	state = STATES.DISCONNECTED
	fsm()
