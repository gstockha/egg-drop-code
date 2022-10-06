extends Node2D

var eggScene = preload("res://Scenes/Egg.tscn")
var eggTimer = 0
var player = null
var botMode = false #if this is the bot's eggparent
var eggTarget = null #the enemy player bot node
var rateBuffer = 0 #artifical egg drop lag for offline
var botTimer = 60
var botIsAbove = false
var botReceive = false #"receiving" from a bot?
var botReceiveLoc = 0 #bots send player eggs in a pattern
var eggRates = {
	0: [8,12],
	1: [5,9],
	2: [3,6],
	3: [1,3]
}
var eggTypes = {
	"normal": { "speed": 2.5, "size": 1.25, "knockback": 200.0, "damage": 1 },
	"fast": { "speed": 3.2, "size": 1, "knockback": 100.0, "damage": 1 },
	"big": { "speed": 2.0, "size": 2, "knockback": 350.0, "damage": 1 }
}
var lowerBounds = 850
var spawnRange = Vector2.ZERO
var myid = 0
var slowMo = 1

func _ready():
	eggTimer = rand_range(eggRates[Global.level][0], eggRates[Global.level][1])
	botMode = get_parent().name == "Enemyspace"
	if !botMode:
		myid = Global.id
		player = get_parent().get_node('Chicken')
		spawnRange = Vector2(Global.playerBounds.x+6,Global.playerBounds.y-6)
		if !Global.online:
			eggTarget = get_node('../../EnemyNode/Enemyspace/EggParent')
			Global.sid = Global.id - 1 if Global.id - 1 >= 0 else 11
			botIsAbove = true
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
		eggTimer = rand_range(eggRates[Global.level][0], eggRates[Global.level][1])
		if botMode && !Global.gameOver:
			if rateBuffer < 60: rateBuffer += 5
			eggTimer += rateBuffer
		elif !botReceive && botIsAbove:
			if Global.sid == Global.eid: return
			rateBuffer += 1
			if randi() % 100 + 1 < rateBuffer:
				botTimer = eggTimer * .5
				botReceive = true
				botReceiveLoc = (randi() % 100) * .01
		makeEgg(99, randType(Global.normalcy), Vector2(rand_range(spawnRange.x, spawnRange.y), 0))
	elif botReceive:
		if botTimer > 0: botTimer -= 10 * delta
		else:
			rateBuffer -= rand_range(2,5)
			var choice = [-1,1]
			botReceiveLoc += rand_range(.01,.25) * choice[randi() % 2]
			while botReceiveLoc < 0.01 || botReceiveLoc > 1:
				botReceiveLoc += rand_range(.01,.25) * choice[randi() % 2]
			if rateBuffer <= 0:
				rateBuffer = 0
				botReceive = false
			else: botTimer = rand_range(eggRates[Global.level][0], eggRates[Global.level][1]) * .5
			makeEgg(Global.sid, randType(Global.normalcy),
			Vector2(spawnRange.x + ((spawnRange.y - spawnRange.x) * botReceiveLoc), 0))

func _physics_process(_delta):
	for egg in get_children():
		egg.position.y += egg.speed * slowMo
		if egg.position.y > lowerBounds:
			egg.queue_free()
			if (egg.id != myid && egg.id != 99) || eggTarget == null: return
			if !Global.online:
				if !botMode: eggTarget.makeEgg(egg.id, egg.type, Vector2(Global.botBounds.y*((egg.position.x-11)/960),0))
				else: eggTarget.makeEgg(egg.id, egg.type, Vector2(egg.position.x*2,0))
#			else: #network
		
func makeEgg(id: int, type: String, pos: Vector2):
	var egg = eggScene.instance()
	var typeKey = eggTypes[type]
	egg.type = type
	egg.size = typeKey["size"]
	egg.scale = Vector2(egg.size, egg.size)
	add_child(egg)
	egg.speed = typeKey["speed"]
	egg.knockback = typeKey["knockback"]
	egg.damage = typeKey["damage"]
	egg.id = id
	egg.position = pos
	if id != 99:
		egg.sprite.modulate = Global.eggColorMap[id]
		if (!botMode && Global.id == id) || (botMode && Global.eid == id): 
			egg.speed *= 2
#			egg.sprite.modulate.a = .75

func randType(normalcy: int) -> String:
	var roll = randi() % 100 + 1
	if roll <= normalcy: return "normal"
	var remainder = 100 - normalcy
	roll =  remainder - (roll - normalcy)
	if (roll <= remainder * .75): return "fast"
	return "big"
