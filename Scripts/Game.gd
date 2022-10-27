extends Control

var colorPlates = []
var namePlates = []
var nameArrows = []
var statusLabels = []
var playerStats = []
var barKeys = []
var heartIcons = []
var powerIcons = []
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
var targetHearts = []
var offsetIds = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
var powerups = {"shrink": preload("res://Sprites/Items/Shrink.png"), "shield": preload("res://Sprites/Items/ShieldItem.png"),
"gun": preload("res://Sprites/Items/CornGun.png"), "butter": preload("res://Sprites/Items/Butter.png")}
onready var gameOverLabels = {"BG": $GameOverBG, "label": $GameOverBG/Label,
"sublabel": $GameOverBG/SubLabel, "subsub": $GameOverBG/SubSubLabel}
onready var hud = {"timer": $BottomHUD/Timer, "eggs": $BottomHUD/SentLabel, "laid": $BottomHUD/LaidLabel,
"shelled": $BottomHUD/ShelledLabel, "powerbar": $BottomHUD/PowerBar,
"levelegg": $BottomHUD/LevelEgg, "level": $BottomHUD/LevelLabel}
onready var playerBG = get_node("PlayerContainer/Viewport/PlayerBG")
onready var playerBorder = get_node("PlayerContainer/Viewport/PlayerBGBorder")
onready var enemyBG = get_node("EnemyContainer/Viewport/EnemyBG")
onready var enemyBorder = get_node("EnemyContainer/Viewport/EnemyBGBorder")
onready var player = $PlayerContainer/Viewport/Playspace/Chicken
onready var timerBar = $BottomHUD/TimerBar

func _ready():
	randomize()
	$MuteButton.self_modulate.a = .6 if Global.muted else 1
	#define ids
	Global.eid = Global.id + 1 if Global.id + 1 < 12 else 0
	Global.sid = Global.id - 1 if Global.id - 1 >= 0 else 11
	eggParent.myid = Global.id
	$EnemyContainer/Viewport/Enemyspace/EggParent.myid = Global.eid
	player.id = Global.id
	$EnemyContainer/Viewport/Enemyspace/ChickenBot.id = Global.eid
	Global.arrangeNames()
	#define nodes
	for i in range(1,13):
		if (i < 7):
			colorPlates.append(get_node("NamePlates/ScoresTop/NamePlate" + str(i)))
			namePlates.append(get_node("NamePlates/ScoresTop/NamePlate" + str(i) + "/Name"))
			statusLabels.append(get_node("NamePlates/ScoresTop/NamePlate" + str(i) + "/StatusLabel"))
			heartIcons.append(get_node("NamePlates/ScoresTop/NamePlate" 
			+ str(i) + "/Hearts/HeartIconActives").get_children())
			powerIcons.append(get_node("NamePlates/ScoresTop/NamePlate" + str(i) + "/Powerup"))
		else:
			colorPlates.append(get_node("NamePlates/ScoresBottom/NamePlate" + str(i-6)))
			namePlates.append(get_node("NamePlates/ScoresBottom/NamePlate" + str(i-6) + "/Name"))
			statusLabels.append(get_node("NamePlates/ScoresBottom/NamePlate" + str(i-6) + "/StatusLabel"))
			heartIcons.append(get_node("NamePlates/ScoresBottom/NamePlate" 
			+ str(i-6) + "/Hearts/HeartIconActives").get_children())
			powerIcons.append(get_node("NamePlates/ScoresBottom/NamePlate" + str(i-6) + "/Powerup"))
	nameArrows = get_node("NamePlates/Arrows").get_children()
	#create nameplate offset
	var offset = 0
	var storedOffset = 0
	var id = Global.id
	while id + offset != 5:
		offset += 1
		if id + offset > 11:
			storedOffset = offset
			offset = 0
			id = 0
	offset += storedOffset
	var c = 0
	for i in range(12):
		if offsetIds[i] + offset > 11:
			offsetIds[i] = c
			c += 1
		else: offsetIds[i] += offset
	#nameplates
	for i in range(12):
		if i != Global.id: botCount += 1
		playerStats.append({"id" : i, "name": Global.botNameMap[i], "color": Global.colorIdMap[i],
		"health": 5, "bot": i != Global.id})
		barKeys.append(i)
		colorPlates[offsetIds[i]].self_modulate = Global.colorIdMap[i]
		nameArrows[offsetIds[i]].self_modulate = Global.colorIdMap[i]
		namePlates[offsetIds[i]].text = Global.botNameMap[i]
	#paint the player and target back grounds
	playerBG.modulate = Global.colorIdMap[Global.id]
	playerBorder.modulate = Global.colorIdMap[Global.id]
	enemyBG.modulate = Global.colorIdMap[Global.eid]
	enemyBorder.modulate = Global.colorIdMap[Global.eid]
	#assign status labels
	statusLabels[offsetIds[Global.id]].text = '[YOU]'
	statusLabels[offsetIds[Global.eid]].text = '[TARGET]'
	statusLabels[offsetIds[Global.sid]].text = '[SEND]'
	for i in range(5): targetHearts.append(get_node("EnemyContainer/Viewport/Hearts/HeartIconActives/HeartIcon" + str(i+1)))

func _input(event):
	if event.is_action_pressed("restart"):
		if !Global.online:
			Global.defaults()
			get_tree().reload_current_scene()
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
		if $EnemyContainer/Viewport.get_child_count() > 3: return
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
	powerIcons[offsetIds[id]].visible = false
	heartIcons[offsetIds[id]][0].get_parent().visible = false
	if id == Global.eid: targetHearts[0].get_parent().visible = false
	colorPlates[offsetIds[id]].self_modulate.a = .3
	namePlates[offsetIds[id]].self_modulate.a = .5
	nameArrows[offsetIds[id]].visible = false
	if Global.gameOver == false:
		if id == Global.eid && !Global.playerDead:
			$GameSFX.playSound("killconfirm")
			confirmedShells += 1
			var hisX = ($EnemyContainer/Viewport/Enemyspace/ChickenBot.global_position.x * 2) + 16
			$PopupParent.makePopup(playerStats[id]["name"], Vector2(hisX, 780), true)
		if Global.playerCount == 1 && playerStats[Global.id]["health"] > 0: #win game
			$GameSFX.playSound("win")
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
	if Global.eid == Global.sid:
		eggParent.botReceive = false
		$EnemyContainer/Viewport/Enemyspace/EggParent.eggTarget = eggParent

func registerHealth(id: int, lastHitId: int, health: int) -> void:
	if Global.playerCount == 1: return
	health = clamp(health, 0, 5)
	var prevhp = playerStats[id]["health"]
	playerStats[id]["health"] = health
	for i in range(5): heartIcons[offsetIds[id]][i].visible = i < health
	if id == Global.eid:
		if prevhp > health: $HitSFX.playSound("hit", randi() % 3)
		for i in range(5): targetHearts[i].visible = i < health
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
			var chicken = $EnemyContainer/Viewport/Enemyspace/ChickenBot if !me else player
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
					statusLabels[offsetIds[i]].text = '' if i != Global.eid else '[SPEC]'
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
			if statusLabels[offsetIds[i]].text == '[TARGET]' || statusLabels[offsetIds[i]].text == '[SPEC]':
				statusLabels[offsetIds[i]].text = ''
				break
		$EnemyContainer/Viewport/Enemyspace.queue_free()
		botIsSpawned = false
		statusLabels[offsetIds[newId]].text = "[TARGET]" if !Global.playerDead else "[SPEC]"
	else:
		for i in range(12):
			if statusLabels[offsetIds[i]].text == '[SEND]':
				statusLabels[offsetIds[i]].text = ''
				break
		if !Global.playerDead: statusLabels[offsetIds[newId]].text = "[SEND]"
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
		var lastHit = player.lastHitId
		var textChoices = ["YOU'VE BEEN PLUCKED", "YOU WERE SHELLED", "YOU WERE SCRAMBLED", "YOU GOT CLUCKED",
		"YOU'VE BEEN FRIED", "YOU GOT TURNED INTO TENDIES", "YOU GOT COCK-A-DOODLE-DOO'D", "YOU BECAME A FAMILY MEAL"]
		gameOverLabels["label"].text = textChoices[randi() % len(textChoices)]
		gameOverLabels["sublabel"].text = "BY "
		gameOverLabels["sublabel"].text += playerStats[lastHit]["name"] if lastHit != 99 else "THE CHICKEN GODS"
		gameOverLabels["subsub"].text = "Press Up or Down to change spectate\nPress ESC to leave, R to restart"

func makeBot() -> void:
	botIsSpawned = true
	$EnemyContainer/Viewport.add_child(enemySpace.instance())
	enemyBG.modulate = playerStats[Global.eid]["color"]
	enemyBorder.modulate = playerStats[Global.eid]["color"]
	eggParent.eggTarget = $EnemyContainer/Viewport/Enemyspace/EggParent
	if playerStats[Global.eid]["bot"]:
		var chicken = $EnemyContainer/Viewport/Enemyspace/ChickenBot
		chicken.position = Vector2(rand_range(Global.botBounds.x+10, Global.botBounds.y-10),
		chicken.position.y + rand_range(-20,20))
		var eggRoll = randi() % 100 + 1
		if eggRoll < 75: eggRoll = round(rand_range(0,5))
		else: eggRoll = round(rand_range(5,20))
		chicken.eggCount = eggRoll
		if eggRoll - 1 > 0: for i in range(eggRoll-1): chicken.eggs[i] = 'normal'
		chicken.scale = Vector2(chicken.baseScale.x + (.05 * eggRoll), chicken.baseScale.y + (.05 * eggRoll))
		chicken.baseSpriteScale = chicken.sprite.scale
		chicken.weight = chicken.baseWeight + (eggRoll * .0002)
		chicken.health = playerStats[Global.eid]["health"]
		targetHearts[0].get_parent().visible = true
		for i in range(5): targetHearts[i].visible = i < chicken.health
		#make fake velocity
		var rnd = [-1,1]
		for i in range(len(chicken.dirListx)):
			chicken.dirListx[i] = rnd[randi() % 2]
			chicken.dirListy[i] = rnd[randi() % 2]
		#make fake eggs
		var eggP = $EnemyContainer/Viewport/Enemyspace/EggParent
		eggP.botEggCount = eggRoll
		var myEnemy = findNewTarget(Global.eid, false, false)
		eggP.botIsAbove = myEnemy != Global.id
		if Global.sid == Global.eid:
			eggP.eggTarget = eggParent
			eggParent.botReceive = false
		var chickenY = chicken.position.y
		var yroll
		for _i in range(rand_range(2 + (1 * Global.level), 8 + (3 * Global.level))):
			yroll = round(rand_range(10,720))
			while yroll < chickenY + 10 && yroll > chickenY - 10: yroll = round(rand_range(10,720))
			eggP.makeEgg(99, eggP.randType(Global.normalcy), Vector2(rand_range(Global.botBounds.x, Global.botBounds.y), yroll))

func calculateGameTime() -> String:
	var lev = Global.level
	var timeBase = 90 - (Global.difficulty * 20) 
	Global.level = clamp(floor(gameTime / timeBase), 0, 5)
	timerBar.value = (((gameTime - (timeBase * Global.level)) / timeBase) * 100) + 1
	if lev != Global.level:
		$PlayerContainer/Viewport/Playspace/ItemParent.powerCooldown = 120 - (Global.level * 7)
		$EnemyContainer/Viewport/Enemyspace/ItemParent.powerCooldown = 120 - (Global.level * 7)
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
		timerBar.modulate = clr
		$EnemyContainer/Viewport/Enemyspace/EggParent.eggRateLevelStr = str(Global.level)
	var mins = int(gameTime) / 60
	var secs = int(gameTime - (mins * 60))
	mins = "0" + str(mins) if mins < 10 else str(mins)
	var timerr = mins + ":"
	timerr += str(secs) if secs > 9 else "0" + str(secs)
	return timerr

func setPowerupIcon(id: int, type: String) -> void:
	if type == "": powerIcons[offsetIds[id]].visible = false
	else:
		powerIcons[offsetIds[id]].visible = true
		powerIcons[offsetIds[id]].texture = powerups[type]

func _on_MuteButton_button_down():
	Global.muted = !Global.muted
	var mstr = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(mstr, Global.muted)
	$MuteButton.self_modulate.a = .6 if Global.muted else 1
