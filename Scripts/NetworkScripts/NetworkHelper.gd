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
enum tags {JOINED, MOVE, EGG, HEALTH, DEATH, STATUS, NEWPLAYER, JOINCONFIRM, EGGCONFIRM}
var playerSpace = null
var chickenDummy = null

func _ready():
	for i in range(12): lobbyChickens.append(null)
	Network.helper = self
	set_physics_process(Global.online)

func _physics_process(_delta):
	if !Global.playerDead:
		movecooldown += 1
		if movecooldown > 3:
			sendMove(player.position, Vector2(player.dir[0], player.dir[1]), str(player.gravity), Global.sid)
			movecooldown = 0

func sendEgg(id: int, type: String, coords: Vector2, bltSpd: float, target: int) -> void:
	Network.send({'tag': tags.EGG, 'id': id, 'type': type, 'x': coords.x, 'y': coords.y, 'bltSpd': bltSpd, 'target': target})

func sendMove(coords: Vector2, vel: Vector2, grav: String, target: int) -> void:
	Network.send({'tag': tags.MOVE, 'x': round(coords.x), 'y': round(coords.y),
	'velx': vel.x, 'vely': vel.y, 'grav': grav, 'target': target})

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

func movePlayer(pos: Vector2, vel: Vector2, grav: String, id: int):
	if Network.lobby:
		if !lobbyChickens[id]: return
		var cPos = lobbyChickens[id].position
		if cPos.x > pos.x - 20 || cPos.x < pos.x + 20: lobbyChickens[id].position.x = pos.x
		if cPos.y > pos.y - 20 || cPos.y < pos.y + 20: lobbyChickens[id].position.y = pos.y
		lobbyChickens[id].dir[0] = vel.x
		lobbyChickens[id].dir[1] = vel.y
		lobbyChickens[id].gravity = float(grav)
