extends Node

const HEADERS = ["Content-Type: application/json"]
const AUTHENTICATION_SERVER = "https://localhost:3001/api"

@onready var http_request = HTTPRequest.new()

signal auth_response(response:bool)

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


func authenticate_with_cookie(username: String, cookie: String) -> bool:
	var body = JSON.stringify({"type": "auth-cookie", "args": {"username": username, "cookie": cookie}})

	var error = http_request.request(AUTHENTICATION_SERVER, HEADERS, HTTPClient.METHOD_POST, body)
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
