extends Node2D

var SOCKET_URL = "ws://127.0.0.1:3000"

var client = WebSocketClient.new()
var helper = null

func _ready():
	client.connect("connection_closed", self, "_on_connection_closed")
	client.connect("connection_error", self, "_on_connection_closed")
	client.connect("connection_established", self, "_on_connected")
	client.connect("data_received", self, "_on_data")

func connectToServer():
	var err = client.connect_to_url(SOCKET_URL)
	if err != OK:
		print('unable to connect!')
		set_process(false)

func _process(_delta):
	client.poll()

func _on_connection_closed(error: bool = false):
	print("closed, error: ", error)
	set_process(false)

func _on_connected(proto: String = ''):
	print('connected with protocol: ', proto)

func send(json) -> void:
	print('sending ', json)
	client.get_peer(1).put_packet(JSON.print(json).to_utf8())

func _on_data() -> void:
	var payload = JSON.parse(client.get_peer(1).get_packet().get_string_from_utf8()).result
	helper.onData(payload)
