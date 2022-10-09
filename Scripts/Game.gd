extends Control

var colorPlates = []
var namePlates = []
var nameArrows = []
var statusLabels = []
var playerStats = []
var barKeys = []
var heartIcons = []
var botIsSpawned = true
var enemySpace = preload("res://Scenes/Enemyspace.tscn")
var deadChicken = preload("res://Sprites/Chickens/DeadChicken.png")
var botCount = 0
var botDamageBuffer = 0
onready var eggParent = $PlayerContainer/Viewport/Playspace/EggParent
#hud shit
var confirmedShells = 0
var confirmedLaid = 0
var confirmedEggs = 0
var gameTime = 0
var recordedTime = null
var hudRefresh = 0
onready var gameOverLabels = {"BG": $GameOverBG, "label": $GameOverBG/Label,
"sublabel": $GameOverBG/SubLabel, "subsub": $GameOverBG/SubSubLabel}
onready var hud = {"timer": $BottomHUD/Timer, "eggs": $BottomHUD/SentLabel, "laid": $BottomHUD/LaidLabel,
"shelled": $BottomHUD/ShelledLabel, "powerbar": $BottomHUD/PowerBar, "levelegg": $BottomHUD/LevelEgg, "level": $BottomHUD/LevelLabel}
onready var playerBG = get_node("PlayerContainer/Viewport/PlayerBG")
onready var enemyBG = get_node("EnemyContainer/Viewport/EnemyBG")

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
	statusLabels[Global.eid].text = '[TARGET]'
	statusLabels[Global.sid].text = '[SEND]'

func _input(event):
	if event.is_action_pressed("fullscreen"): OS.window_fullscreen = !OS.window_fullscreen
	elif event.is_action_pressed("restart"):
		if !Global.online: get_tree().reload_current_scene()
	elif event.is_action_pressed("menu"): get_tree().quit()
	if !Global.playerDead: return
	if event.is_action_pressed("ui_up") || event.is_action_pressed("ui_down"):
		if Global.gameOver: return
		var prev = Global.eid
		Global.eid = findNewTarget(Global.eid, event.is_action("ui_down"), true) #seek new target
		if prev != Global.eid: Global.sid = findNewTarget(Global.eid, false, false) #seek new sender

func _process(delta):
	if botCount > 0: #make fake health changes
		botDamageBuffer += delta * botCount * (.00005 + ((Global.level + 1) * .00005))
		if randf() < botDamageBuffer:
			botDamageBuffer = 0
			var randId = round(rand_range(0,11))
			var tries = 0
			while !playerStats[randId]["bot"] || randId == Global.eid || playerStats[randId]["health"] < 1:
				randId = randId + 1 if randId + 1 < 12 else 0
				tries += 1
				if tries > 12: break
			if tries <= 12:
				var choice = -1 if randf() < .75 else 1
				registerHealth(randId, 99, playerStats[randId]["health"] + choice)
	if !botIsSpawned:
		if $EnemyContainer/Viewport.get_child_count() > 1: return
		if playerStats[Global.eid]["bot"]: makeBot()
		botIsSpawned = true
		if !Global.playerDead:
			eggParent.releaseEggQueue()
			eggParent.eggQueue = false
	if !Global.gameOver:
		gameTime += delta
		hudRefresh += delta
		if hudRefresh > 1:
			hudRefresh = 0
			hud["timer"].text = calculateGameTime()
			hud["eggs"].text = 'x' + str(confirmedEggs)
			hud["laid"].text = 'x' + str(confirmedLaid)
			hud["shelled"].text = 'x' + str(confirmedShells)

func registerDeath(id: int, _lastHitId: int, _disconnect: bool, delayed: Timer) -> void:
	if delayed != null:
		delayed.stop()
		delayed.queue_free()
	playerStats[id]["health"] = 0
	heartIcons[id][0].get_parent().visible = false
	colorPlates[id].self_modulate.a = .3
	namePlates[id].self_modulate.a = .5
	nameArrows[id].visible = false
	playerStats[id].visible = false
#	if id != Global.id: statusLabels[id].text = ''
	if Global.gameOver == false:
		if id == Global.eid && !Global.playerDead:
			confirmedShells += 1
			var hisX = ($EnemyContainer/Viewport/Enemyspace/ChickenBot.global_position.x * 2) + 16
			print(hisX)
			$PopupParent.makePopup(playerStats[id]["name"], Vector2(hisX, 780), true)
		if Global.playerCount == 1 && playerStats[Global.id]["health"] > 0: #win game
			endGame(true, Global.id)
			return
		elif id == Global.id:
			endGame(false, id)
			return
		elif Global.playerCount == 1:
			for i in range(12):
				if playerStats[i]["health"] > 0:
					endGame(false, i)
					break
			return
	if id == Global.eid: Global.eid = findNewTarget(id, true, true) #seek new target
	if id == Global.sid: Global.sid = findNewTarget(id, false, false) #seek new sender
	if Global.eid == Global.sid: #turn off bot egg
		eggParent.botReceive = false
		$EnemyContainer/Viewport/Enemyspace/EggParent.eggTarget = eggParent

func registerHealth(id: int, lastHitId: int, health: int) -> void:
	if Global.playerCount == 1: return
	health = clamp(health, 0, 6)
	playerStats[id]["health"] = health
	for i in range(6): heartIcons[id][i].visible = i < health
	if health < 1:
		Global.playerCount -= 1
		var me = Global.id == id
		var eParent = $EnemyContainer/Viewport/Enemyspace/EggParent if !me else eggParent
		if (me || id == Global.eid) && eParent.slowMo != .5:
			var deathTimer = Timer.new()
			add_child(deathTimer)
			deathTimer.connect("timeout", self, "registerDeath", [id, lastHitId, false, deathTimer])
			deathTimer.start(3)
			eParent.eggTarget = null
			eParent.slowMo = .5
			eParent.player = null
			eParent.set_process(false)
			var chicken = $EnemyContainer/Viewport/Enemyspace/ChickenBot if !me else $PlayerContainer/Viewport/Playspace/Chicken
			chicken.idle = true
			chicken.speed *= .5
			chicken.get_child(0).texture = deadChicken
			if !me:
				$EnemyContainer/Viewport/Enemyspace/ItemParent.player = null
				if !Global.playerDead:
					eggParent.eggQueue = true
					eggParent.eggQueueTime = gameTime
			else: #set up spectate mode
				$PlayerContainer/Viewport/Playspace/ItemParent.player = null
				for i in range(12):
					if i == Global.id: continue
					statusLabels[i].text = '' if i != Global.eid else '[SPEC]'
		else: registerDeath(id, lastHitId, false, null)

func findNewTarget(id: int, below: bool, eid: bool) -> int:
	var tries = 0
	var newId = null
	while(newId == null && tries < 13):
		if below: id = id + 1 if id + 1 < 12 else 0
		else: id = id - 1 if id - 1 >= 0 else 11
		if id == Global.id || playerStats[id]["health"] < 1: continue
		newId = id
		tries += 1
	if newId == null:
		print('target search returned null, eid: ' + str(eid) + ', id: ' + str(id))
		return id
	if eid:
		for i in range(12):
			if statusLabels[i].text == '[TARGET]' || statusLabels[i].text == '[SPEC]':
				statusLabels[i].text = ''
				break
		$EnemyContainer/Viewport/Enemyspace.queue_free()
		botIsSpawned = false
		statusLabels[newId].text = "[TARGET]" if !Global.playerDead else "[SPEC]"
	else:
		for i in range(12):
			if statusLabels[i].text == '[SEND]':
				statusLabels[i].text = ''
				break
		if !Global.playerDead: statusLabels[newId].text = "[SEND]"
	return newId

func endGame(win: bool, winner: int):
	Global.win = win
	gameOverLabels["BG"].visible = true
	if win || (!win && Global.playerCount < 2):
		Global.gameOver = true
		gameOverLabels["label"].text = "You won!" if win else playerStats[winner]["name"] + " wins!"
		gameOverLabels["sublabel"].text = "LAID: " + str(confirmedLaid)
		gameOverLabels["sublabel"].text += "  SHELLS: " + str(confirmedShells)
		if recordedTime == null: gameOverLabels["sublabel"].text += "  TIME: " + hud["timer"].text
		else: gameOverLabels["sublabel"].text += "  TIME: " + recordedTime
		gameOverLabels["subsub"].text = "Press ESC to leave, R to restart"
	else: #spectate
		recordedTime = hud["timer"].text
		Global.playerDead = true
		$EnemyContainer/Viewport/Enemyspace/EggParent.botIsAbove = true
		$EnemyContainer/Viewport/Enemyspace/EggParent.rateBuffer *= .1
		var lastHit = $PlayerContainer/Viewport/Playspace/Chicken.lastHitId
		var textChoices = ["YOU'VE BEEN PLUCKED", "YOU WERE SHELLED", "YOU WERE SCRAMBLED", "YOU GOT CLUCKED",
		"YOU'VE BEEN FRIED", "YOU WERE TURNED INTO TENDIES", "YOU GOT COCK-A-DOODLE-DOO'D"]
		gameOverLabels["label"].text = textChoices[randi() % len(textChoices)]
		gameOverLabels["sublabel"].text = "BY "
		gameOverLabels["sublabel"].text += playerStats[lastHit]["name"] if lastHit != 99 else "THE CHICKEN GODS"
		gameOverLabels["subsub"].text = "Press Up or Down to change spectate\nPress ESC to leave, R to restart"

func makeBot() -> void:
	botIsSpawned = true
	$EnemyContainer/Viewport.add_child(enemySpace.instance())
	enemyBG.modulate = playerStats[Global.eid]["color"]
	eggParent.eggTarget = $EnemyContainer/Viewport/Enemyspace/EggParent
	if playerStats[Global.eid]["bot"]:
		var chicken = $EnemyContainer/Viewport/Enemyspace/ChickenBot
		chicken.position = Vector2(rand_range(Global.botBounds.x+10, Global.botBounds.y-10), chicken.position.y + rand_range(-20,20))
		var eggRoll = randi() % 100 + 1
		if eggRoll < 75: eggRoll = round(rand_range(0,5))
		else: eggRoll = round(rand_range(5,20))
		chicken.eggCount = eggRoll
		chicken.scale = Vector2(chicken.baseScale.x + (.05 * eggRoll), chicken.baseScale.y + (.05 * eggRoll))
		chicken.baseSpriteScale = chicken.sprite.scale
		chicken.weight = chicken.baseWeight + (eggRoll * .0002)
		chicken.health = playerStats[Global.eid]["health"]
		#make fake velocity
		var rnd = [-1,1]
		for i in range(len(chicken.dirListx)):
			chicken.dirListx[i] = rnd[randi() % 2]
			chicken.dirListy[i] = rnd[randi() % 2]
		#make fake eggs
		var eggP = $EnemyContainer/Viewport/Enemyspace/EggParent
		var myEnemy = findNewTarget(Global.eid, false, false)
		eggP.botIsAbove = myEnemy != Global.id
		var chickenY = chicken.position.y
		var yroll
		for _i in range(rand_range(2 + (1 * Global.level), 8 + (3 * Global.level))):
			yroll = round(rand_range(10,720))
			while yroll < chickenY + 10 && yroll > chickenY - 10: yroll = round(rand_range(10,720))
			eggP.makeEgg(99, eggP.randType(Global.normalcy), Vector2(rand_range(Global.botBounds.x, Global.botBounds.y), yroll))

func calculateGameTime() -> String:
	var lev = Global.level
	Global.level = clamp(floor(gameTime / 60), 0, 5)
	if lev != Global.level:
		eggParent.eggRateLevelStr = str(Global.level)
		hud["level"].text = str(Global.level+1)
		var clr = Color.deeppink
		var eggClr = Color.webpurple
		if Global.level == 1:
			clr = Color.green
			eggClr = Color.lightgreen
		elif Global.level == 2:
			clr = Color.gold
			eggClr = Color.palegoldenrod
		elif Global.level == 3:
			clr = Color.orange
			eggClr = Color.peachpuff
		elif Global.level == 4:
			clr = Color.red
			eggClr = Color.pink
		hud["level"].modulate = clr
		hud["levelegg"].modulate = eggClr
		$EnemyContainer/Viewport/Enemyspace/EggParent.eggRateLevelStr = str(Global.level)
	var mins = int(gameTime) / 60
	var secs = int(gameTime - (mins * 60))
	mins = "0" + str(mins) if mins < 10 else str(mins)
	var timerr = mins + ":"
	timerr += str(secs) if secs > 9 else "0" + str(secs)
	return timerr
