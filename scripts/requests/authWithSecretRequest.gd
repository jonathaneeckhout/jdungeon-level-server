extends Node

signal auth_response(response: bool)

@onready var url = "%s/level/login/player" % Global.env_common_server_address

@onready var http_request = HTTPRequest.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	var client_tls_options: TLSOptions

	if Global.env_debug:
		client_tls_options = TLSOptions.client_unsafe()
	else:
		client_tls_options = TLSOptions.client()

	http_request.set_tls_options(client_tls_options)

	add_child(http_request)
	http_request.request_completed.connect(_http_request_completed)


func authenticate_with_secret(username: String, secret: String, cookie: String) -> bool:
	var headers = ["Content-Type: application/json", "Cookie: %s" % cookie]

	var body = JSON.stringify({"username": username, "secret": secret})

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("An error occurred in the HTTP request.")
		return false

	print("Sending out authentication request for %s to %s" % [username, url])

	var response = await auth_response
	return response


# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("HTTPRequest failed")
		auth_response.emit(false)
		return

	if response_code != 200:
		print("Error in response")
		auth_response.emit(false)
		return

	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	if !response.has("error") or response["error"] or !response.has("data"):
		print("Error or invalid response format")
		auth_response.emit(false)
		return

	auth_response.emit(response["data"]["auth"])
