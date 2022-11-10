extends Node2D

var eggScene = preload("res://Scenes/Egg.tscn")
var eggTimer = 0
var player = null
var botMode = false #if this is the bot's eggparent
var eggTarget = null #the enemy player bot node
var rateBuffer = 0 #artifical egg drop lag for offline, or artificial egg receive from invisible sending bots above
var botTimer = 60 #artifical bot receive cooldown
var botLayEgg = [false, 0,0] #bool, buffer, and timer
var botEggCount = 0
var botIsAbove = false #synoymous with not online + non-bot player
var eggQueue = false #enabled when going from one bot to another
var eggQueueList = []
var eggQueueTime = 0
var botReceive = false #"receiving" from a bot? (BOOL SWITCH, not a state)
var botReceiveLoc = 0 #bots send player eggs in a pattern
var eggRates = {
	'0': [7,9],
	'1': [6,8],
	'2': [5,7],
	'3': [4,6],
	'4': [3,5],
	'5': [2,4]
}
var eggRateLevelStr = "0"
var eggTypes = {
	"normal": { "speed": 2.5, "size": 1.25, "knockback": 225.0, "damage": 1, "hp": 2 },
	"fast": { "speed": 3.2, "size": 1, "knockback": 100.0, "damage": 1, "hp": 1 },
	"big": { "speed": 2.0, "size": 2, "knockback": 400.0, "damage": 1, "hp": 4 }
}
var lowerBounds = 850
var spawnRange = Vector2.ZERO
var myid = 0
var slowMo = 1
var game = null
var online = false
var helper = null
var onlineQueue = []
var onlineEggs = {}
var onlinePlayer = false #botmode && not a bot (online)
var botIsBelow = false

func _ready():
	set_physics_process(!Network.lobby)
	eggRateLevelStr = str(Global.level)
	eggTimer = rand_range(eggRates[eggRateLevelStr][0], eggRates[eggRateLevelStr][1])
	botMode = get_parent().name == "Enemyspace"
	if !botMode:
		myid = Global.id
		player = get_parent().get_node('Chicken')
		spawnRange = Vector2(Global.playerBounds.x+6,Global.playerBounds.y-6)
		eggTarget = get_node('../../../../EnemyContainer/Viewport/Enemyspace/EggParent')
		if !Global.online:
			Global.sid = Global.id - 1 if Global.id - 1 >= 0 else 11
			botIsAbove = true
		else: botIsAbove = Global.botList[Global.sid]
#		botIsAbove = Global.id == 0 #DELETE WHEN NOT TESTING!
		game = get_parent().get_parent().get_parent().get_parent()
		helper = Network.helper
		botIsBelow = Global.botList[Global.eid]
#		botIsBelow = false #DELETE WHEN NOT TESTING!
	else:
		myid = Global.eid
		lowerBounds = 425
		spawnRange = Vector2(Global.botBounds.x+3,Global.botBounds.y-3)
		for key in eggTypes:
			eggTypes[key]["speed"] *= .5
			eggTypes[key]["size"] *= .5
		onlinePlayer = !Global.botList[myid]
#		onlinePlayer = myid != 1 #DELETE WHEN NOT TESTING!
		set_process(Global.botList[myid])
#		set_process(myid != 1) #DELETE WHEN NOT TESTING!
	set_process(!Network.lobby) #UNCOMMENT WHEN NOT TESTING

func _process(delta):
	eggTimer -= 10 * delta
	if eggTimer < 1:
		eggTimer = rand_range(eggRates[eggRateLevelStr][0], eggRates[eggRateLevelStr][1])
		if (!botMode && !botIsAbove) || (botMode && !Global.playerDead):
			#eggparent stop producing neutral eggs so much if receiving from above
			if rateBuffer < (60 + (Global.level * 10)): rateBuffer += 3 + Global.difficulty
			eggTimer += rateBuffer
		elif !botReceive && botIsAbove: #fake bot receive ticker
			if Global.sid == Global.eid: return
			rateBuffer += .5 + (Global.level * .2)
			if randi() % 100 + 1 < rateBuffer:
				botTimer = eggTimer * .5
				botReceive = true
				botReceiveLoc = (randi() % 100) * .01
		var vec = Vector2(rand_range(spawnRange.x, spawnRange.y), 0)
		var type = randType(Global.normalcy)
		makeEgg(99, type, vec)
		if !botMode:
			if !botIsAbove: Network.sendEgg(99, type, vec, 1, Global.sid, false) #to enemy's enemy screen
			if Network.spectated: Network.sendEgg(99, type, vec, 1, 99, false) #to enemy's enemy screen
	elif botReceive: #receive artificial eggs from above
		if botTimer > 0: botTimer -= 10 * delta
		else:
			rateBuffer -= rand_range(3,6) - (Global.difficulty * .5)
			var choice = [-1,1]
			botReceiveLoc += rand_range(.01,.25) * choice[randi() % 2]
			while botReceiveLoc < 0.01 || botReceiveLoc > 1:
				botReceiveLoc += rand_range(.01,.25) * choice[randi() % 2]
			if rateBuffer <= 0:
				rateBuffer = 0
				botReceive = false
			else: botTimer = rand_range(eggRates[eggRateLevelStr][0], eggRates[eggRateLevelStr][1]) * .5
			var type = randType(Global.normalcy)
			var vec = Vector2(spawnRange.x + ((spawnRange.y - spawnRange.x) * botReceiveLoc), 0)
			makeEgg(Global.sid, type, vec)
			if Network.spectated: Network.sendEgg(Global.sid, type, vec, 1, 99, false) #to spectator's enemy screen
	if botMode: #actually lay eggs when visible
		if !botLayEgg[0]:
			if botEggCount > 0: botLayEgg[1] += delta * botEggCount
			if randi() % 1000 < botLayEgg[1]:
				botLayEgg[2] = eggTimer * .5
				botLayEgg[0] = true
		else:
			botLayEgg[2] -= delta * 10
			if botLayEgg[2] < 1:
				botLayEgg[1] -= rand_range(.0003,.0008)
#				print('botlayegg1: ' + str(botLayEgg[1]) + ', eggcount: ' + str(player.eggCount))
				if player.eggCount < 1 || botLayEgg[1] < 0:
					botLayEgg[0] = false
					botLayEgg[1] = 0
					return
				player.MakeEgg(false)
				botLayEgg[2] = rand_range(3, 8)

func _physics_process(_delta):
	for egg in get_children():
		egg.position.y += egg.speed * slowMo
		if egg.position.y > lowerBounds:
			egg.queue_free()
			if onlinePlayer:
				var eggId = str(round(egg.position.x*2))
				if eggId in onlineEggs: onlineEggs.erase(eggId)
			if eggTarget == null || (egg.id != myid && egg.id != 99): return
			if !botMode && (!Global.online || botIsBelow):
				if !eggQueue: eggTarget.makeEgg(egg.id, egg.type, Vector2(egg.position.x * .5, 0), egg.spdBoost)
				elif egg.id == myid:
					eggQueueList.append([egg.id, egg.type, Vector2(egg.position.x * .5,0),
					egg.spdBoost, game.gameTime - eggQueueTime])
					eggQueueTime = game.gameTime
			#bot sends to player in a 1v1
			elif botMode: eggTarget.makeEgg(egg.id, egg.type, Vector2(egg.position.x * 2, 0), egg.spdBoost)
			else: #player network send to player
				Network.sendEgg(egg.id, egg.type, Vector2(egg.position.x, 0),
				egg.spdBoost, Global.eid)
				onlineQueue.append([egg.id, egg.type, Vector2(egg.position.x * .5, 0), egg.spdBoost])
		
func makeEgg(id: int, type: String, pos: Vector2, eggSpdBoost: float = 1):
	var egg = eggScene.instance()
	var typeKey = eggTypes[type]
	add_child(egg)
	egg.type = type
	egg.size = typeKey["size"]
	egg.scale = Vector2(egg.size, egg.size)
	egg.speed = typeKey["speed"] * eggSpdBoost
	egg.spdBoost = eggSpdBoost
	egg.knockback = typeKey["knockback"]
	egg.damage = typeKey["damage"]
	egg.hp = typeKey["hp"]
	egg.id = id
	egg.position = pos
	if onlinePlayer && id != myid: onlineEggs[str(round(pos.x*2))] = egg
	if id != 99:
		egg.sprite.modulate = Global.colorIdMap[id]
		if !botMode && Global.id == id:
			egg.speed *= 2
			if !botIsAbove: Network.sendEgg(id, type, pos, eggSpdBoost, Global.sid, false) #to enemy's enemy screen
			if Network.spectated: Network.sendEgg(id, type, pos, eggSpdBoost, 99, false) #to enemy's enemy screen
		elif botMode && Global.eid == id: egg.speed *= 2
		else: egg.speed *= 1.25
		if !botMode: game.confirmedEggs += 1

func randType(normalcy: int) -> String:
	var roll = randi() % 100 + 1
	if roll <= normalcy: return "normal"
	var remainder = 100 - normalcy
	roll =  remainder - (roll - normalcy)
	if (roll <= remainder * .75): return "fast"
	return "big"

func releaseEggQueue(timer: Timer = null):
	if timer != null:
		timer.stop()
		timer.queue_free()
	if len(eggQueueList) < 1 || Global.playerDead || Global.gameOver || eggTarget == null:
		eggQueueList = []
		return
	var eggInfo = eggQueueList.pop_front()
	if Global.botList[Global.eid]: eggTarget.makeEgg(eggInfo[0], eggInfo[1], eggInfo[2], eggInfo[3])
	else:
		Network.sendEgg(eggInfo[0], eggInfo[1], eggInfo[2], eggInfo[3], Global.eid)
		onlineQueue.append([eggInfo[0], eggInfo[1], Vector2(Global.botBounds.y*((eggInfo[2].x-11)/960),0), eggInfo[3]])
	var queueTimer = Timer.new()
	game.add_child(queueTimer)
	queueTimer.connect("timeout", self, "releaseEggQueue", [queueTimer])
	queueTimer.start(eggInfo[4])

func onlineEggQueue() -> void: #to sync with the player behind us' screen (delayed drop)
	if len(onlineQueue) < 1: return
	var eggInfo = onlineQueue.pop_front()
	eggTarget.makeEgg(eggInfo[0], eggInfo[1], eggInfo[2], eggInfo[3])

func activateWildcard() -> void:
	var egg
	var clr = Global.colorIdMap[myid]
	for i in range(len(get_children())):
		egg = get_child(i)
		if egg.id == myid: continue
		egg.id = myid
		egg.sprite.modulate = clr
		egg.speed *= 1.5

func onlineHit(eggId: String) -> void:
	if eggId in onlineEggs:
		if player.shielded == false:
			player.screenShake = 15 + (onlineEggs[eggId].knockback * .04)
			player.shakeTimer = 25 + (player.screenShake * 1.3)
		onlineEggs[eggId].queue_free()
		onlineEggs.erase(eggId)
