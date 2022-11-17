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
var foundDummy = true
onready var onlineLabel = get_node("../OnlineLabel")
onready var menu = get_node("../Menu")
var spawnMod = []

func _ready():
	for _i in range(12): lobbyChickens.append(null)
	Network.helper = self
	set_physics_process(Global.online)
	Network.spectated = false
	Global.playerDead = false
	Global.gameOver = false
	Global.win = null
	for i in range(12):
		if i < 6: spawnMod.append(435 - (65 * i))
		else: spawnMod.append(515 + (65 * (i - 6)))

func _physics_process(_delta):
	if !Global.playerDead:
		movecooldown += 1
		if movecooldown > 4: #send basic move
			Network.sendMove(player.position, Vector2(player.dir[0], player.dir[1]), str(player.gravity), Global.sid)
			movecooldown = 0

func removePlayer(id: int, wasActive: bool) -> void:
	Global.botList[id] = true
	Global.nameMap[id] = null
	if Network.lobby || !wasActive:
		if lobbyChickens[id] == null: return
		lobbyChickens[id].queue_free()
		lobbyChickens[id] = null
		game.setNameplateName(id)
	else: game.registerHealth(id, 0, 0)

func addLobbyPlayer(id: int) -> void:
	if lobbyChickens[id] != null: return
	var chick = chickenDummy.instance()
	playerSpace.add_child(chick)
	chick.nameLabel.modulate = Global.colorIdMap[id]
	chick.nameLabel.text = Global.nameMap[id]
	chick.nameLabel.visible = true
	chick.position = Vector2(spawnMod[id],480)
	chick.id = id
	lobbyChickens[id] = chick
	chick.scale *= 2
	chick.speed = 400
	chick.visible = false
	chick.hitboxboxDisable(true)
	game.setNameplateName(id)

func movePlayer(pos: Vector2, vel: Vector2, grav: String, id: int, shoveCounter = null, shoveVel = null, dir = null):
	if !foundDummy: return
	var chicken = null
	var cPos
	if enemy != null && Global.eid == id:
		chicken = enemy
#		if chicken == null || enemy == null: return
#		if chicken.id != id: return
		pos *= .5
		cPos = chicken.position
		if cPos.x > pos.x - 10 || cPos.x < pos.x + 10: chicken.position.x = pos.x
		if cPos.y > pos.y - 10 || cPos.y < pos.y + 10: chicken.position.y = pos.y
	elif Network.lobby && lobbyChickens[id] != null:
		chicken = lobbyChickens[id]
#		if chicken == null || lobbyChickens[id] == null: return
		cPos = chicken.position
		if cPos.x > pos.x - 20 || cPos.x < pos.x + 20: chicken.position.x = pos.x
		if cPos.y > pos.y - 20 || cPos.y < pos.y + 20: chicken.position.y = pos.y
		if !chicken.visible:
			chicken.visible = true
			chicken.hitboxboxDisable(false)
	else: return
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
	if !foundDummy: return
	enemyItemParent.addOnlineItem(itemId, category, type, position, duration)

func destroyOnlineItem(itemId: String, eat: bool) -> void:
	if !foundDummy: return
	enemyItemParent.deleteOnlineItem(itemId, eat)
	if eat: warpPlayer(Global.eid, false)

func setStatus(id: int, powerup: String, scale: String) -> void:
	if !Global.botList[id]:
		var chicken = null
		if enemy != null && Global.eid == id: chicken = enemy
		elif Network.lobby: chicken = lobbyChickens[id]
		if chicken != null:
			if !foundDummy: return
			chicken.scale = Vector2(float(scale), float(scale))
		if powerup != "none":
			game.setPowerupIcon(id, powerup)
			if chicken != null: chicken.setPowerup(powerup)
	elif powerup != "none": game.setPowerupIcon(id, powerup)

func setHealth(id: int, lastHit: int, health: int, eggId: String, justSet: bool = false) -> void:
	if eggId != "0" && !Global.botList[id] && id == Global.eid:
		if !foundDummy: return
		enemyEggParent.onlineHit(eggId)
		warpPlayer(id, true)
	game.registerHealth(id, lastHit, health, justSet)

func warpPlayer(id: int, hurt: bool = false) -> void:
	var chicken = null
	if enemy != null && Global.eid == id:
		if !foundDummy: return
		chicken = enemy
	elif Network.lobby: chicken = lobbyChickens[id]
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
	game.targetPlayerLoad["scale"] = str(float(scale) * 2)
	game.targetPlayerLoad["x"] = x
	game.targetPlayerLoad["y"] = y
	game.targetPlayerLoaded = true

func setPlayerIdle(id: int, idle: bool) -> void:
	if id == Global.eid && !Global.botList[id] && enemy != null && enemy.onlineIdle != null:
		if !foundDummy: return
		enemy.onlineIdle = idle

func getBotHealth() -> Array:
	var healthList = []
	for i in range(12):
		if Global.botList[i]: healthList.append(game.playerStats[i]["health"])
		else: healthList.append(99)
	return healthList

func closeMenu() -> void:
	if menu.visible: menu._on_MainButton_button_up()
