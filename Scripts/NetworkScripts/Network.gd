extends Node2D

var SOCKET_URL = "ws://127.0.0.1:3000"

var client = WebSocketClient.new()
var helper = null
enum tags {JOINED, MOVE, SHOOT, HEALTH, DEATH, STATUS, NEWPLAYER, JOINCONFIRM, PLAYERLEFT}

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
	Global.lobby = false
	set_process(false)

func _on_connected(proto: String = ''):
	print('connected to server!')

func send(json) -> void:
	print('sending ', json)
	client.get_peer(1).put_packet(JSON.print(json).to_utf8())

func _on_data() -> void:
	var data = JSON.parse(client.get_peer(1).get_packet().get_string_from_utf8()).result
	match int(data.tag):
		tags.JOINED: #JOINED a confirm by the server we've joined, send back our pref. name and id
			send({'tag': tags['JOINED'], 'prefID': Global.prefID, 'name': Global.playerName})
		tags.MOVE: #MOVE
			pass
		tags.SHOOT: #SHOOT
			pass
		tags.HEALTH: #HEALTH
			pass
		tags.STATUS: #STATUS
			pass
		tags.DEATH: #DEATH
			pass
		tags.NEWPLAYER: #NEWPLAYER
			Global.nameMap[data.id] = data.name
			print("New player joined: ", Global.nameMap[data.id])
			Global.playerCount -= 1
			if Global.lobby: helper.addLobbyPlayer(data.id)
		tags.JOINCONFIRM: #JOINCONFIRM receive our assigned id and player name list
			Global.id = int(data.id)
			Global.playerName = data.name
			Global.nameMap = data.nameMap
			Global.joined = true
			Global.lobby = data.lobby
			print("Join confirmed!")
			print("Your assigned ID: ", Global.id)
			print("Playerlist: ", Global.nameMap)
			Global.playerCount = 0
			for i in range(len(Global.nameMap)): if Global.nameMap[i] != null: Global.playerCount += 1
		tags.PLAYERLEFT:
			Global.playerCount = int(data.playerCount)
			print(Global.nameMap[data.id] + ' left the game')
			Global.nameMap[data.id] = null
			if Global.lobby: helper.removeLobbyPlayer(data.id)
