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
		if movecooldown > 3:
			Network.sendMove(player.position, Vector2(player.dir[0], player.dir[1]), str(player.gravity), Global.sid,
			str(player.shoveCounter[0]), player.shoveVel)
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

func movePlayer(pos: Vector2, vel: Vector2, grav: String, id: int, shoveCounter = null, shoveVel = null):
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
	if shoveCounter != null:
		chicken.shoveCounter[0] = float(shoveCounter)
		chicken.shoveCounter[1] = float(shoveCounter)
		chicken.shoveVel = shoveVel

func bumpPlayer(direction: String, dirChange: int):
	player.KnockBack(direction, dirChange, 50, 50, 0)
