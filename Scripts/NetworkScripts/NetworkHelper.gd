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
enum tags {JOINED, MOVE, EGG, HEALTH, DEATH, STATUS, NEWPLAYER, JOINCONFIRM, EGGCONFIRM, BUMP}
var playerSpace = null
var chickenDummy = null

func _ready():
	for i in range(12): lobbyChickens.append(null)
	Network.helper = self
	set_physics_process(Global.online)

func _physics_process(_delta):
	if !Global.playerDead:
		movecooldown += 1
		if movecooldown > 3: #send basic move
			Network.sendMove(player.position, Vector2(player.dir[0], player.dir[1]), str(player.gravity), Global.sid)
			movecooldown = 0

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
	chick.id = id
	lobbyChickens[id] = chick

func movePlayer(pos: Vector2, vel: Vector2, grav: String, id: int, shoveCounter = null, shoveVel = null, dir = null):
	var chicken
	if Network.lobby:
		if !lobbyChickens[id]: return
		chicken = lobbyChickens[id]
	else: chicken = enemy
	var cPos = chicken.position
	if cPos.x > pos.x - 20 || cPos.x < pos.x + 20: chicken.position.x = pos.x
	if cPos.y > pos.y - 20 || cPos.y < pos.y + 20: chicken.position.y = pos.y
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
	elif lobbyChickens[id]: lobbyChickens[id].KnockBack(direction, dirChange, 50, 50, 0, false)

func itemSent(create: bool, category: String, itemId: int, eat: bool, type: String, position: Vector2):
	if create: enemyItemParent.addOnlineItem(category, type, position)
	else: enemyItemParent.deleteOnlineItem(itemId, eat)
