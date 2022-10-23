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
var botReceive = false #"receiving" from a bot?
var botReceiveLoc = 0 #bots send player eggs in a pattern
var eggRates = {
	'0': [8,12],
	'1': [7,10.5],
	'2': [6,9],
	'3': [4,6.5],
	'4': [3,5.5],
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

func _ready():
	eggRateLevelStr = str(Global.level)
	eggTimer = rand_range(eggRates[eggRateLevelStr][0], eggRates[eggRateLevelStr][1])
	botMode = get_parent().name == "Enemyspace"
	if !botMode:
		myid = Global.id
		player = get_parent().get_node('Chicken')
		spawnRange = Vector2(Global.playerBounds.x+6,Global.playerBounds.y-6)
		if !Global.online:
			eggTarget = get_node('../../../../EnemyContainer/Viewport/Enemyspace/EggParent')
			Global.sid = Global.id - 1 if Global.id - 1 >= 0 else 11
			botIsAbove = true
		game = get_parent().get_parent().get_parent().get_parent()
	else:
		myid = Global.eid
		player = get_parent().get_node('ChickenBot')
		lowerBounds = 425
		spawnRange = Vector2(Global.botBounds.x+3,Global.botBounds.y-3)
		for key in eggTypes:
			eggTypes[key]["speed"] *= .5
			eggTypes[key]["size"] *= .5

func _process(delta):
	eggTimer -= 10 * delta
	if eggTimer < 1:
		eggTimer = rand_range(eggRates[eggRateLevelStr][0], eggRates[eggRateLevelStr][1])
		if botMode && !Global.playerDead: #bot's eggparent stop producing neutral eggs so much if receiving from above
			if rateBuffer < (60 + (Global.level * 10)): rateBuffer += 5 + Global.difficulty
			eggTimer += rateBuffer
		elif !botReceive && botIsAbove:
			if Global.sid == Global.eid: return
			rateBuffer += .5 + (Global.level * .2)
			if randi() % 100 + 1 < rateBuffer:
				botTimer = eggTimer * .5
				botReceive = true
				botReceiveLoc = (randi() % 100) * .01
		makeEgg(99, randType(Global.normalcy), Vector2(rand_range(spawnRange.x, spawnRange.y), 0))
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
			makeEgg(Global.sid,randType(Global.normalcy),Vector2(spawnRange.x+((spawnRange.y-spawnRange.x)*botReceiveLoc),0))
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
			if eggTarget == null || (egg.id != myid && egg.id != 99): return
			if !Global.online:
				if !botMode:
					if !eggQueue:
						eggTarget.makeEgg(egg.id, egg.type,
						Vector2(Global.botBounds.y*((egg.position.x-11)/960),0), egg.spdBoost)
					elif egg.id == myid:
						eggQueueList.append([egg.id, egg.type,
						Vector2(Global.botBounds.y*((egg.position.x-11)/960),0),
						egg.spdBoost, game.gameTime - eggQueueTime])
						eggQueueTime = game.gameTime
				else: eggTarget.makeEgg(egg.id, egg.type, Vector2(egg.position.x*2,0), egg.spdBoost)
#			else: #network
		
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
	if id != 99:
		egg.sprite.modulate = Global.colorIdMap[id]
		if (!botMode && Global.id == id) || (botMode && Global.eid == id): 
			egg.speed *= 2
		elif !botMode: game.confirmedEggs += 1

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
	eggTarget.makeEgg(eggInfo[0], eggInfo[1], eggInfo[2], eggInfo[3])
	var queueTimer = Timer.new()
	game.add_child(queueTimer)
	queueTimer.connect("timeout", self, "releaseEggQueue", [queueTimer])
	queueTimer.start(eggInfo[4])

func activateWildcard() -> void:
	var egg
	var clr = Global.colorIdMap[myid]
	for i in range(len(get_children())):
		egg = get_child(i)
		if egg.id == myid: continue
		egg.id = myid
		egg.sprite.modulate = clr
		egg.speed *= 1.5
