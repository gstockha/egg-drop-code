extends Node2D

var eggParent = null
var itemParent = null
var player = null
var enemy = null
var lobbyChickens = []
var enemyEggParent = null
var enemyItemParent = null
var game = get_parent()
var movecooldown = 0
enum tags {JOINED, MOVE, SHOOT, HEALTH, DEATH, STATUS, NEWPLAYER, JOINCONFIRM}
var playerSpace = null
var chickenDummy = null

func _ready():
	for i in range(12): lobbyChickens.append(null)
	Network.helper = self
	set_process(Global.online)

func _process(delta):
	if !Global.playerDead:
		movecooldown += 10 * delta
		if movecooldown >= 3:
			sendMove(player.position, Vector2(player.dir[0], player.dir[1]), player.dirString(), Global.sid)
			movecooldown = 0

func sendEgg(id: int, type: String, coords: Vector2, bltSpd: float, onPlayer: bool, target: int) -> void:
	Network.send({'tag': tags.SHOOT, 'id': id, 'type': type, 'x': coords.x, 'y': coords.y, 'bltSpd': bltSpd,
	'onPlayer': onPlayer, 'target': target})

func sendMove(coords: Vector2, vel: Vector2, dir: String, target: int) -> void:
	Network.send({'tag': tags.MOVE, 'velx': vel.x, 'vely': vel.y, 'x': coords.x, 'y': coords.y, 'dir': dir, 'target': target})

func sendHealth(health: int) -> void:
	Network.send({'tag': tags.HEALTH, 'health': health})

func sendDeath() -> void:
	Network.send({'tag': tags.DEATH})

func sendStatus(powerup: String, size: float) -> void:
	Network.send({'tag': tags.STATUS, 'powerup': powerup, 'size': size})

func removeLobbyPlayer(id: int) -> void:
	if lobbyChickens[id] == null: return
	lobbyChickens[id].queue_free()
	lobbyChickens[id] = null

func addLobbyPlayer(id: int) -> void:
	var chick = chickenDummy.instance()
	playerSpace.add_child(chick)
	chick.nameLabel.self_modulate = Global.colorIdMap[id]
	chick.nameLabel.text = Global.nameMap[id]
	chick.nameLabel.visible = true
	chick.position = Vector2(480,480)
	lobbyChickens[id] = chick

func movePlayer(pos: Vector2, vel: Vector2, dir: String, id: int):
	if Network.lobby:
		if !lobbyChickens[id]: return
		lobbyChickens[id].position = pos
		lobbyChickens[id].dir[0] = vel.x
		lobbyChickens[id].dir[1] = vel.y
		var dirList = dir.split('|', true, 0)
		var pointer = 0
		for i in range(12):
			lobbyChickens[id].dirListx[i] = int(dirList[pointer]) * .1
			lobbyChickens[id].dirListy[i] = int(dirList[pointer + 1]) * .1
			pointer += 2
