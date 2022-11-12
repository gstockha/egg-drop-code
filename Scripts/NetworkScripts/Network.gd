extends Node2D

var SOCKET_URL = "ws://127.0.0.1:3000"

var client = WebSocketClient.new()
onready var helper = FakeHelper
enum tags {JOINED, MOVE, EGG, HEALTH, READY, STATUS, NEWPLAYER, JOINCONFIRM, PLAYERLEFT, EGGCONFIRM, BUMP, ITEMSEND,
ITEMDESTROY, FULL, LABEL, BEGIN, TARGETSTATUS, SPECTATE, IDLE, ENDGAME, LOBBYPLAYER}
var attemptingConnection = false
var lobby = false
var waitingForGame = false
var joined = false
var onlineLabelSet = [null, null]
var spectated = false
var lastWinner = 99

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
	Network.lobby = false
	set_process(false)
	Network.attemptingConnection = false

func _on_connected(_proto):
	print('connected to server!')

func send(json) -> void:
	client.get_peer(1).put_packet(JSON.print(json).to_utf8())

func sendEgg(id: int, type: String, coords: Vector2, bltSpd: float, target: int, toPlayer: bool = true) -> void:
	send({'tag': tags.EGG, 'id': id, 'type': type, 'x': round(coords.x), 'y': round(coords.y),
	'bltSpd': bltSpd, 'target': target, 'toPlayer': toPlayer})

func sendMove(coords: Vector2, vel: Vector2, grav: String, target: int,
shoveCounter: String = '0', shoveVel = null, dir = null) -> void:
	send({'tag': tags.MOVE, 'x': round(coords.x), 'y': round(coords.y), 'velx': vel.x, 'vely': vel.y,
	'grav': grav, 'shoveCounter': shoveCounter, 'shoveVel': shoveVel, 'dir': dir, 'target': target})

func sendHealth(id: int, lastHit: int, health: int, eggId: float) -> void:
	send({'tag': tags.HEALTH, 'id': id, 'lastHit': lastHit, 'health': health, 'eggId': str(round(eggId))})

func sendReady() -> void:
	send({'tag': tags.READY})

func sendStatus(id: int, powerup: String, scale: String) -> void:
	send({'tag': tags.STATUS, 'id': id, 'powerup': powerup, 'scale': scale})

func sendBump(direction: String, dirChange: int, target: int) -> void:
	send({'tag': tags.BUMP, 'direction': direction, 'dirChange': dirChange, 'target': target})

func sendItemCreate(itemId: String, category: String, type: String, position: Vector2, duration: float, target: int) -> void:
	send({'tag': tags.ITEMSEND, 'itemId': itemId,'category': category, 'type': type, 'x': round(position.x),
	'y': round(position.y), 'duration': round(duration), 'target': target})

func sendItemDestroy(itemId: String, eat: bool, target: int) -> void:
	send({'tag': tags.ITEMDESTROY, 'itemId': itemId, 'eat': eat, 'target': target})

func sendStatusRequest(target: int) -> void:
	send({'tag': tags.TARGETSTATUS, 'target': target})

func sendSpectateStatus(target: int, spectating: bool) -> void:
	send({'tag': tags.SPECTATE, 'target': target, 'spectating': spectating})

func sendLobbyReturn() -> void:
	send({'tag': tags.LOBBYPLAYER, 'id': Global.id})

func sendEndGame() -> void:
	send({'tag': tags.ENDGAME})

func _on_data() -> void:
	var data = JSON.parse(client.get_peer(1).get_packet().get_string_from_utf8()).result
	match int(data.tag):
		tags.JOINED: #JOINED a confirm by the server we've joined, send back our pref. name and id
			if Global.version != data.version:
				print('outdated version!')
				client.disconnect_from_host(1000, "version")
				return
			send({'tag': tags.JOINED, 'prefID': Global.prefID, 'name': Global.playerName})
		tags.MOVE: #MOVE
			helper.movePlayer(Vector2(data.x, data.y), Vector2(data.velx, data.vely), data.grav, data.id,
			data.shoveCounter, data.shoveVel, data.dir)
		tags.EGG: #EGG
			if data.toPlayer:
				helper.eggParent.makeEgg(data.id, data.type, Vector2(data.x, data.y), data.bltSpd)
				send({'tag': tags.EGGCONFIRM, 'target': data.sender })
			elif helper.enemyEggParent != null:
				helper.enemyEggParent.makeEgg(data.id, data.type, Vector2(data.x, data.y) * .5, data.bltSpd)
				if data.id == Global.eid: helper.warpPlayer(data.id)
		tags.HEALTH: #HEALTH
			helper.setHealth(data.id, data.lastHit, data.health, data.eggId)
		tags.STATUS: #STATUS
			helper.setStatus(data.id, data.powerup, data.scale)
		tags.READY:
			sendReady() #READY
		tags.NEWPLAYER: #NEWPLAYER
			Global.nameMap[data.id] = data.name
			Global.botList[data.id] = true #is currently a bot (regardless if a player slot)
			Global.activeList[data.id] = true #is a player or not (in game or in lobby)
			Global.idleList[data.id] = false
			print("New player joined: ", Global.nameMap[data.id])
			Global.playerCount += 1
			if Network.lobby: helper.addLobbyPlayer(data.id)
		tags.JOINCONFIRM: #JOINCONFIRM receive our assigned id and player name list
			Global.id = int(data.id)
			Global.playerName = data.name
			Global.nameMap = data.nameMap
			joined = true
			waitingForGame = data.lobby
			lobby = true
			print("Join confirmed!")
			print("Your assigned ID: ", Global.id)
			print("Playerlist: ", Global.nameMap)
			Global.playerCount = 0
			for i in range(len(Global.nameMap)):
				if Global.nameMap[i] != null:
					Global.playerCount += 1
					Global.activeList[i] = true
			for i in range(len(data.bottedPlayers)): #which slots are currently bots
				Global.botList[data.bottedPlayers[i]["id"]] = !data.bottedPlayers[i]["active"]
		tags.PLAYERLEFT:
			Global.botList[data.id] = true
			Global.playerCount = int(data.playerCount)
			print(Global.nameMap[data.id] + ' left the game')
			Global.nameMap[data.id] = null
			Global.activeList[data.id] = false
			helper.removePlayer(data.id)
		tags.EGGCONFIRM:
			helper.eggParent.onlineEggQueue()
		tags.BUMP:
			helper.bumpPlayer(data.direction, data.dirChange, data.target)
		tags.ITEMSEND:
			helper.addOnlineItem(data.itemId, data.category, data.type, Vector2(data.x, data.y), data.duration)
		tags.ITEMDESTROY:
			helper.destroyOnlineItem(data.itemId, data.eat)
		tags.FULL: print('Game full!')
		tags.LABEL:
			if Network.waitingForGame: helper.setOnlineLabel(data.label, data.timer)
			else: FakeHelper.setOnlineLabel(data.label, data.timer)
		tags.BEGIN:
			lobby = false
			waitingForGame = false
			for i in range(12):
				Global.botList[i] = !Global.activeList[i]
				helper.lobbyChickens[i] = null
			var _nuScene = get_tree().reload_current_scene()
		tags.TARGETSTATUS:
			helper.setTargetStatus(data.scale, data.x, data.y)
		tags.SPECTATE:
			spectated = data.spectated
		tags.IDLE:
			helper.setPlayerIdle(data.id, data.idle)
			if data.idle: print(Global.nameMap[data.id] + ' idle!')
		tags.ENDGAME:
			lobby = true
			waitingForGame = true
			lastWinner = data.winner
			var _nuScene = get_tree().reload_current_scene()
		tags.LOBBYPLAYER:
			Global.botList[data.id] = true
			if Network.lobby: helper.addLobbyPlayer(data.id)
