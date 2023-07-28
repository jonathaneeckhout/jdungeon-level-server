extends Node

signal request_response(res: bool)

@onready var debug = Env.get_value("DEBUG")
@onready var common_server_address = Env.get_value("COMMON_SERVER_ADDRESS")
@onready var url = "%s/api/character/stats" % common_server_address

@onready var http_request = HTTPRequest.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	var client_tls_options: TLSOptions

	if debug == "true":
		client_tls_options = TLSOptions.client_unsafe()
	else:
		client_tls_options = TLSOptions.client()

	http_request.set_tls_options(client_tls_options)

	add_child(http_request)
	http_request.request_completed.connect(_http_request_completed)


func save_character_stats(
	character: String, current_level: int, experience: int, cookie: String
) -> bool:
	var headers = ["Content-Type: application/json", "Cookie: %s" % cookie]

	var body = JSON.stringify(
		{"character": character, "experience": experience, "experience_level": current_level}
	)

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("An error occurred in the HTTP request.")
		return false

	print("Sending out save character stats request for %s to %s" % [character, url])

	var response = await request_response
	return response


# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("HTTPRequest failed")
		request_response.emit(false)
		return

	if response_code != 200:
		print("Error in response")
		request_response.emit(false)
		return

	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	if !response.has("error") or response["error"]:
		print("Error or invalid response format")
		request_response.emit(false)
		return

	request_response.emit(true)
