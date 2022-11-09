extends Node2D

var eggParent = null
var itemParent = null
var player = null
var enemy = null
var lobbyChickens = []
var enemyEggParent = null
var enemyItemParent = null
var game = null
var movecooldown = 0
#enum tags {JOINED, MOVE, EGG, HEALTH, DEATH, STATUS, NEWPLAYER, JOINCONFIRM, PLAYERLEFT, EGGCONFIRM, BUMP, ITEMSEND,
#ITEMDESTROY}
var playerSpace = null
var chickenDummy = null
onready var onlineLabel = get_node("../OnlineLabel")

func _ready():
	for i in range(12): lobbyChickens.append(null)
	Network.helper = self
	set_physics_process(Global.online)

func _physics_process(_delta):
	if !Global.playerDead:
		movecooldown += 1
		if movecooldown > 4: #send basic move
			Network.sendMove(player.position, Vector2(player.dir[0], player.dir[1]), str(player.gravity), Global.sid)
			movecooldown = 0

func removeLobbyPlayer(id: int) -> void:
	if lobbyChickens[id] == null: return
	lobbyChickens[id].queue_free()
	lobbyChickens[id] = null

func addLobbyPlayer(id: int) -> void:
	var chick = chickenDummy.instance()
	playerSpace.add_child(chick)
	chick.nameLabel.modulate = Global.colorIdMap[id]
	chick.nameLabel.text = Global.nameMap[id]
	chick.nameLabel.visible = true
	chick.position = Vector2(480,480)
	chick.id = id
	lobbyChickens[id] = chick
	chick.scale *= 2
	chick.speed = 400
	game.setNameplateName(id)

func movePlayer(pos: Vector2, vel: Vector2, grav: String, id: int, shoveCounter = null, shoveVel = null, dir = null):
	var chicken = null
	var cPos
	if Network.lobby:
		chicken = lobbyChickens[id]
		cPos = chicken.position
		if cPos.x > pos.x - 20 || cPos.x < pos.x + 20: chicken.position.x = pos.x
		if cPos.y > pos.y - 20 || cPos.y < pos.y + 20: chicken.position.y = pos.y
	else:
		chicken = enemy
		pos *= .5
		cPos = chicken.position
		if cPos.x > pos.x - 10 || cPos.x < pos.x + 10: chicken.position.x = pos.x
		if cPos.y > pos.y - 10 || cPos.y < pos.y + 10: chicken.position.y = pos.y
	if chicken == null: return
	chicken.dir[0] = vel.x
	chicken.dir[1] = vel.y
	chicken.gravity = float(grav)
	if shoveVel != null:
		chicken.shoveCounter[0] = float(shoveCounter)
		chicken.shoveCounter[1] = float(shoveCounter)
		chicken.shoveVel = shoveVel
		var dirList = dir.split('|')
		var pointer = 0
		for i in range(12):
			chicken.dirListx[i] = float(dirList[pointer]) * .1
			chicken.dirListy[i] = float(dirList[pointer + 1]) * .1
			pointer += 2

func bumpPlayer(direction: String, dirChange: int, id: int):
	if id == Global.id: player.KnockBack(direction, dirChange, 50, 50, 0, true)
	elif lobbyChickens[id] != null: lobbyChickens[id].KnockBack(direction, dirChange, 50, 50, 0, false)

func addOnlineItem(itemId: String, category: String, type: String, position: Vector2, duration: int) -> void:
	enemyItemParent.addOnlineItem(itemId, category, type, position, duration)

func destroyOnlineItem(itemId: String, eat: bool) -> void:
	enemyItemParent.deleteOnlineItem(itemId, eat)

func setStatus(id: int, powerup: String, scale: String) -> void:
	var chicken = null
	if Network.lobby: chicken = lobbyChickens[id]
	elif id == Global.eid && !Global.botList[id]: chicken = enemy
	if chicken != null: chicken.baseSpriteScale = Vector2(float(scale), float(scale))
	if powerup != "none":
		game.setPowerupIcon(id, powerup)
		if chicken != null: chicken.setPowerup(powerup)

func setHealth(id: int, lastHit: int, health: int, eggId: String) -> void:
	game.registerHealth(id, lastHit, health)
	if id == Global.eid && eggId != "0" && !Network.lobby:
		enemyEggParent.onlineHit(eggId)
		warpPlayer(id, true)

func warpPlayer(id: int, hurt: bool = false) -> void:
	var chicken = null
	if Network.lobby: chicken = lobbyChickens[id]
	elif enemy != null: chicken = enemy
	if chicken == null: return
	var xsc = 1.3 if !hurt else .7
	var ysc = .7 if !hurt else 1.3
	chicken.Squish(Vector2(enemy.baseSpriteScale.x * xsc, enemy.baseSpriteScale.y * ysc))

func setOnlineLabel(set: String, timer: int = 0) -> void:
	onlineLabel.text = set
	if timer != 0:
		onlineLabel.timerOn = true
		onlineLabel.timer = timer

func setTargetStatus(scale: String, x: String, y: String) -> void:
	game.targetPlayerLoad["scale"] = scale
	game.targetPlayerLoad["x"] = x
	game.targetPlayerLoad["y"] = y
	game.targetPlayerLoaded = true
