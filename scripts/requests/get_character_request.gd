extends Node

const HEADERS = ["Content-Type: application/json"]
const AUTHENTICATION_SERVER = "https://localhost:3001/api"

@onready var http_request = HTTPRequest.new()

signal request_response(response)

var cert = load("res://data/certs/app/X509_certificate.crt")

# Called when the node enters the scene tree for the first time.
func _ready():
	#TODO: Use this function instead of debug function
	# var client_tls_options = TLSOptions.client(cert)
	#TODO: Remove next line
	var client_tls_options = TLSOptions.client_unsafe(cert)

	http_request.set_tls_options(client_tls_options)

	add_child(http_request)
	http_request.request_completed.connect(_http_request_completed)


func get_character(character_name: String):
	var url = "%s/characters/%s" % [AUTHENTICATION_SERVER, character_name]
	var error = http_request.request(url, HEADERS, HTTPClient.METHOD_GET)
	if error != OK:
		print("An error occurred in the HTTP request.")
		return null
	else:
		var response = await request_response

		return response


# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, _headers, body):

	if result != HTTPRequest.RESULT_SUCCESS:
		request_response.emit(null)
		return

	if response_code != 200:
		print("Error in response")
		return

	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	if !"error" in response or response["error"] or !"data" in response:
		request_response.emit(null)
		return

	var data = response["data"]
	data["position"] = Vector2(response["data"]["position"]["x"], response["data"]["position"]["y"])

	request_response.emit(data)
