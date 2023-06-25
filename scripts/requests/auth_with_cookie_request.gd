extends Node

const HEADERS = ["Content-Type: application/json"]
const AUTHENTICATION_SERVER = "http://localhost:3001/api"

@onready var http_request = HTTPRequest.new()

signal auth_response(response:bool)


# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(http_request)
	http_request.request_completed.connect(_http_request_completed)


func authenticate_with_cookie(username: String, cookie: String) -> bool:
	var body = JSON.stringify({"type": "auth-cookie", "args": {"username": username, "cookie": cookie}})

	var error = http_request.request(AUTHENTICATION_SERVER, HEADERS, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
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

	# Will print the user agent string used by the HTTPRequest node (as recognized by httpbin.org).
	print(response)

	auth_response.emit(response["data"]["auth"])
