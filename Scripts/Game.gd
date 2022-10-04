extends Control

var colorPlates = []
var namePlates = []
var nameArrows = []
var statusLabels = []
var playerStats = []
var barKeys = []
var heartIcons = []
var enemyActive = true
var enemySpace = preload("res://Scenes/Enemyspace.tscn")
var botCount = 0
var botDamageBuffer = 0
onready var playerBG = get_node("PlayerBG")
onready var enemyBG = get_node("EnemyBG")
onready var eggParent = $Playspace/EggParent

func _ready():
	for i in range(1,13):
		if (i < 7):
			colorPlates.append(get_node("NamePlates/ScoresTop/NamePlate" + str(i)))
			namePlates.append(get_node("NamePlates/ScoresTop/NamePlate" + str(i) + "/Name"))
			statusLabels.append(get_node("NamePlates/ScoresTop/NamePlate" + str(i) + "/StatusLabel"))
			heartIcons.append(get_node("NamePlates/ScoresTop/NamePlate" 
			+ str(i) + "/Hearts/HeartIconActives").get_children())
		else:
			colorPlates.append(get_node("NamePlates/ScoresBottom/NamePlate" + str(i-6)))
			namePlates.append(get_node("NamePlates/ScoresBottom/NamePlate" + str(i-6) + "/Name"))
			statusLabels.append(get_node("NamePlates/ScoresBottom/NamePlate" + str(i-6) + "/StatusLabel"))
			heartIcons.append(get_node("NamePlates/ScoresBottom/NamePlate" 
			+ str(i-6) + "/Hearts/HeartIconActives").get_children())
	nameArrows = get_node("NamePlates/Arrows").get_children()
	var bot
	for i in range(12):
		if i != Global.id:
			bot = true
			botCount += 1
		else: bot = false
		playerStats.append({"id" : i, "name": Global.botNameMap[i], "color": Global.colorIdMap[i], "health": 6, "bot": bot})
		barKeys.append(i)
		colorPlates[i].self_modulate = Global.colorIdMap[i]
		nameArrows[i].self_modulate = Global.colorIdMap[i]
		namePlates[i].text = Global.botNameMap[i]
	#paint the player and target back grounds
	playerBG.modulate = Global.colorIdMap[Global.id]
	enemyBG.modulate = Global.colorIdMap[Global.eid]
	#assign status labels
	statusLabels[Global.id].text = '[YOU]'
	statusLabels[Global.id+1].text = '[TARGET]'
	statusLabels[Global.id-1].text = '[SEND]'

func _input(event):
	if event.is_action_pressed("fullscreen"): OS.window_fullscreen = !OS.window_fullscreen

func _process(delta):
	if botCount > 0:
		botDamageBuffer += delta * botCount * (.0005 + (Global.level * .0002)) * 100
		if randf() < botDamageBuffer:
			botDamageBuffer = 0
			var randId = round(rand_range(0,11))
			randId = Global.sid
			var tries = 0
			while !playerStats[randId]["bot"] || randId == Global.eid:
				randId = randId + 1 if randId + 1 < 12 else 0
				tries += 1
				if tries > 12: break
			recordHealth(randId, 99, playerStats[randId]["health"] - 1)
	if !enemyActive:
		if playerStats[Global.eid]["bot"]: makeBot()

func registerDeath(id: int, _lastHitId: int, _disconnect: bool) -> void:
	playerStats[id]["health"] = 0
	heartIcons[id][0].get_parent().visible = false
	colorPlates[id].self_modulate.a = .3
	namePlates[id].self_modulate.a = .5
	nameArrows[id].visible = false
	playerStats[id].visible = false
	statusLabels[id].text = ""
	Global.playerCount -= 1
	if Global.playerCount == 1 && playerStats[Global.id]["health"] > 0:
		print("you win!")
		return
	if id == Global.eid: #seek new target
		var s = id + 1 if id + 1 < 12 else 0
		var tries = 0
		for i in range(s, 12):
			if i == Global.id: continue;
			if playerStats[i]["health"] >= 1:
				statusLabels[i].text = "[TARGET]"
				Global.eid = i
				break
			tries += 1
			if tries > 11: break
			if i == 11: i = -1
		$EnemyNode/Enemyspace.queue_free()
		enemyActive = false
	if id == Global.sid: #seek new sender
		var s = id - 1 if id - 1 >= 0 else 11
		var tries = 0
		for i in range(s, 12):
			if i == Global.id: continue;
			if playerStats[i]["health"] >= 1:
				if i != Global.eid: statusLabels[i].text = "[SEND]"
				Global.sid = i
				break
			tries += 1
			if tries > 11: break
			if i == 11: i = -1
	if Global.eid == Global.sid: #turn off bot egg
		eggParent.botReceive = false
		$EnemyNode/Enemyspace/EggParent.eggTarget = eggParent

func recordHealth(id: int, lastHitId: int, health: int) -> void:
	playerStats[id]["health"] = health
	if id == Global.id: return
	if health < 1:
		registerDeath(id, lastHitId, false)
		return
	for i in range(6): heartIcons[id][i].visible = i < health

func makeBot() -> void:
	enemyActive = true
	var espace = enemySpace.instance()
	$EnemyNode.add_child(espace)
	espace.global_position = Vector2(992, 201)
	enemyBG.modulate = playerStats[Global.eid]["color"]
	eggParent.eggTarget = $EnemyNode/Enemyspace/EggParent
	if playerStats[Global.eid]["bot"]:
		var chicken = $EnemyNode/Enemyspace/ChickenBot
		chicken.position = Vector2(rand_range(Global.botBounds.x, Global.botBounds.y), chicken.position.y + rand_range(-20,20))
		var eggRoll = randi() % 100 + 1
		if eggRoll < 75: eggRoll = round(rand_range(0,5))
		else: eggRoll = round(rand_range(5,20))
		chicken.eggCount = eggRoll
		chicken.scale = Vector2(chicken.baseScale.x + (.05 * eggRoll), chicken.baseScale.y + (.05 * eggRoll))
		chicken.baseSpriteScale = chicken.sprite.scale
		chicken.weight = chicken.baseWeight + (eggRoll * .0002)
		#make fake velocity
		var rnd = [-1,1]
		for i in range(len(chicken.dirListx)):
			chicken.dirListx[i] = rnd[randi() % 2]
			chicken.dirListy[i] = rnd[randi() % 2]
		#make fake eggs
		var eggP = $EnemyNode/Enemyspace/EggParent
		var chickenY = chicken.position.y
		var yroll
		for _i in range(randi() % 12):
			yroll = round(rand_range(10,720))
			while yroll < chickenY + 20 && yroll > chickenY - 20: yroll = round(rand_range(10,720))
			eggP.makeEgg(99, eggP.randType(Global.normalcy), Vector2(rand_range(Global.botBounds.x, Global.botBounds.y), yroll))
