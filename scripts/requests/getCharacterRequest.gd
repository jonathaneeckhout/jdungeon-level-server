extends Node

signal request_response(response)

@onready var debug = Env.get_value("DEBUG")
@onready var common_server_address = Env.get_value("COMMON_SERVER_ADDRESS")
@onready var url = "%s/api" % common_server_address

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


func get_character(character_name: String, cookie: String):
	var request_url = "%s/characters/%s" % [url, character_name]
	var headers = ["Content-Type: application/json", "Cookie: %s" % cookie]

	var error = http_request.request(request_url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("An error occurred in the HTTP request.")
		return null

	print("Sending out get request to %s" % [request_url])

	var response = await request_response
	return response


# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("HTTPRequest failed")
		request_response.emit(null)
		return

	if response_code != 200:
		print("Error in response")
		request_response.emit(null)
		return

	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	if !"error" in response or response["error"] or !"data" in response:
		print("Error or invalid response format")
		request_response.emit(null)
		return

	var data = response["data"]
	data["position"] = Vector2(response["data"]["position"]["x"], response["data"]["position"]["y"])

	request_response.emit(data)
