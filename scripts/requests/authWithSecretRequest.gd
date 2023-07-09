extends Node

@onready var debug = Env.get_value("DEBUG")
@onready var common_server_address = Env.get_value("COMMON_SERVER_ADDRESS")
@onready var url = "%s/level/login/player" % common_server_address

@onready var http_request = HTTPRequest.new()

signal auth_response(response:bool)

# Called when the node enters the scene tree for the first time.
func _ready():
	var client_tls_options: TLSOptions

	if debug =="true":
		client_tls_options = TLSOptions.client_unsafe()
	else:
		client_tls_options = TLSOptions.client()

	http_request.set_tls_options(client_tls_options)

	add_child(http_request)
	http_request.request_completed.connect(_http_request_completed)


func authenticate_with_secret(username: String, secret: String, cookie: String) -> bool:
	var headers =  ["Content-Type: application/json", "Cookie: %s" % cookie ]

	var body = JSON.stringify({"username": username, "secret": secret})

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("An error occurred in the HTTP request.")
		return false
	else:
		var response = await auth_response

		return response


# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, _headers, body):

	if result != HTTPRequest.RESULT_SUCCESS:
		auth_response.emit(false)
		return

	if response_code != 200:
		print("Error in response")
		return

	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	if !response.has("error") or response["error"] or !response.has("data"):
		auth_response.emit(false)
		return

	auth_response.emit(response["data"]["auth"])
