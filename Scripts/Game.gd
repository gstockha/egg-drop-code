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
var chickenSprite = preload("res://Sprites/Chickens/Chicken.png")
var chickenBot = preload("res://Scenes/ChickenBot.tscn")
var chickenDummy = preload("res://Scenes/ChickenDummy.tscn")
var botCount = 0
var botDamageBuffer = 0
onready var eggParent = $PlayerContainer/Viewport/Playspace/EggParent
#hud shit
var confirmedShells = 0
var confirmedLaid = 0
var confirmedEggs = 0
var recordedTime = null
var aliveCount = 12
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
var enemy = null#$EnemyContainer/Viewport/Enemyspace/ChickenBot
onready var enemyEggParent = $EnemyContainer/Viewport/Enemyspace/EggParent
onready var enemyItemParent = $EnemyContainer/Viewport/Enemyspace/ItemParent
onready var timerBar = $BottomHUD/TimerBar
onready var enemyArrow = $PlayerContainer/Viewport/EnemyArrow
var targetPlayerLoaded = false #for getting a new online target
var targetPlayerLoad = {"x": '0', "y": '0', "scale": '0'}
var lastEggBuffer = 0

func _ready():
	randomize()
	$MuteButton.self_modulate.a = .6 if Global.muted else 1
	#define ids
	Global.eid = Global.id + 1 if Global.id + 1 < 12 else 0
	Global.sid = Global.id - 1 if Global.id - 1 >= 0 else 11
	eggParent.myid = Global.id
	enemyEggParent.myid = Global.eid
#	enemyEggParent.set_process(Global.eid != 1) #DELETE WHEN NOT TESTING!
	player.id = Global.id
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
	var name
	for i in range(12):
		if i != Global.id: botCount += 1
		name = Global.nameMap[i] if Global.nameMap[i] != null else Global.botNameMap[i] + '[bot]'
		playerStats.append({"id" : i, "name": name, "color": Global.colorIdMap[i],
		"health": 5})
		barKeys.append(i)
		colorPlates[offsetIds[i]].self_modulate = Global.colorIdMap[i]
		nameArrows[offsetIds[i]].self_modulate = Global.colorIdMap[i]
		namePlates[offsetIds[i]].text = playerStats[i]["name"]
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
	#online shit
	if Global.online:
		$NetworkHelper.itemParent = $PlayerContainer/Viewport/Playspace/ItemParent
		$NetworkHelper.player = player
		$NetworkHelper.eggParent = eggParent
		$NetworkHelper.enemyEggParent = enemyEggParent
		$NetworkHelper.enemyItemParent = enemyItemParent
		$NetworkHelper.chickenDummy = chickenDummy
		$NetworkHelper.playerSpace = $PlayerContainer/Viewport/Playspace
		$NetworkHelper.game = self
		if FakeHelper.playerHealthSaved: #preloaded health values
			FakeHelper.playerHealthSaved = false
			for i in range(len(FakeHelper.playerHealthSave)): registerHealth(i, 99, FakeHelper.playerHealthSave[i], true)
	else:
		Global.botList[Global.id] = true
		for i in range(12): Global.activeList[i] = false
	#define enemy
	if !Network.lobby:
		var chick
		if Global.botList[Global.eid]: chick = chickenBot.instance()
		else:
			chick = chickenDummy.instance()
			chick.onlineIdle = Network.idleList[Global.eid]
		$EnemyContainer/Viewport/Enemyspace.add_child(chick)
		enemy = $EnemyContainer/Viewport/Enemyspace/ChickenBot
		enemyItemParent.player = enemy
		enemyEggParent.player = enemy
		$NetworkHelper.enemy = enemy
		enemy.id = Global.eid
		enemyArrow.changeColor(Global.eid)
#		enemyEggParent.set_process(!Network.waitingForGame && !(!Global.botList[Global.eid] && Global.activeList[Global.eid]))
	else:
		player.position = Vector2($NetworkHelper.spawnMod[Global.id],480)
		set_process(false)
		if Network.waitingForGame:
			for i in range(12):
				if i != Global.id && Global.activeList[i]: $NetworkHelper.addLobbyPlayer(i)
		else:
			for i in range(12):
				if i != Global.id && Global.botList[i] && Global.activeList[i]: $NetworkHelper.addLobbyPlayer(i)

func _input(event):
	if event.is_action_pressed("restart"):
		if !Global.online:
			Global.defaults()
			get_tree().reload_current_scene()
	elif event.is_action_pressed("admin_start"):
		if Global.id != 5 || !Network.lobby || !Network.waitingForGame: return
		Network.sendAdminStart()
	if !Global.playerDead: return
	if event.is_action_pressed("ui_up") || event.is_action_pressed("ui_down"):
		if Global.gameOver: return
		var prev = Global.eid
		Global.eid = findNewTarget(Global.eid, event.is_action("ui_down"), true) #seek new target
		if prev != Global.eid: Global.sid = findNewTarget(Global.eid, false, false) #seek new sender
	elif event.is_action_pressed("ui_accept"):
		if !Global.online || Network.lobby || !Global.playerDead: return
		Network.lobby = true
		Network.sendLobbyReturn()
		Network.spectated = false
		$PlayerContainer/Viewport/Playspace/ItemParent.deactivate()
		eggParent.deactivate()
		Global.playerDead = false
#		Global.gameOver = false
#		set_process(false)
		player.sprite.texture = chickenSprite
		player.idle = false
		player.speed = 400
		player.scale = Vector2(2,2)
		player.baseSpriteScale = player.sprite.scale
		player.position = Vector2($NetworkHelper.spawnMod[Global.id],480)
		gameOverLabels["BG"].visible = false
		eggParent.slowMo = 1
		$OnlineLabel.visible = true
		$OnlineLabel.text = 'Waiting for new game...'
		for i in range(12):
			if i != Global.id && Global.botList[i] && Global.activeList[i]: $NetworkHelper.addLobbyPlayer(i)

func _process(delta):
	if !Global.online: #make fake health changes
		botDamageBuffer += delta * botCount * (.00005 + ((Global.level + 1) * .00005))
		if randf() < botDamageBuffer:
			botDamageBuffer = 0
			var randId = round(rand_range(0,11))
			var tries = 0
			while randId == Global.id || randId == Global.eid || playerStats[randId]["health"] < 1:
				randId = randId + 1 if randId + 1 < 12 else 0
				tries += 1
				if tries > 12: break
			if tries <= 12:
				var choice = -1 if randf() < .75 else 1
				registerHealth(randId, 99, playerStats[randId]["health"] + choice)
	if !botIsSpawned:
		if $EnemyContainer/Viewport.get_child_count() > 3: return
		if Global.online && !Global.botList[Global.eid] && !targetPlayerLoaded: return
		targetPlayerLoaded = false
		Network.helper.foundDummy = true
		makeBot()
		if !Global.playerDead:
			eggParent.releaseEggQueue()
			eggParent.eggQueue = false
	elif !Global.playerDead && enemy != null: enemyArrow.position.x = (enemy.position.x * 2) - 20
	if !Global.gameOver:
		Global.gameTime += delta
		hudRefresh += delta
		if hudRefresh > 1:
			hudRefresh = 0
			hud["timer"].text = calculategameTime()
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
	if id == Global.eid:
		targetHearts[0].get_parent().visible = false
	colorPlates[offsetIds[id]].self_modulate.a = .3
	namePlates[offsetIds[id]].self_modulate.a = .5
	nameArrows[offsetIds[id]].visible = false
	if Global.gameOver == false:
		if id == Global.eid && !Global.playerDead && !Network.lobby:
			$GameSFX.playSound("killconfirm")
			confirmedShells += 1
			var hisX = (enemy.global_position.x * 2) + 16
			$PopupParent.makePopup(playerStats[id]["name"], Vector2(hisX, 780), true)
			enemyArrow.visible = false
		if aliveCount == 1 && playerStats[Global.id]["health"] > 0 && !Network.lobby: #win game
			$GameSFX.playSound("win")
			endGame(true, Global.id)
			return
		elif id == Global.id: #you dead
			endGame(false, id)
			enemyArrow.visible = false
			if Global.online && Global.botList[Global.eid]:
				var lasteid = Global.eid
				Global.eid = findNewTarget(lasteid, true, true) #seek player to spectate
				if lasteid != Global.eid:
					Network.sendStatusRequest(Global.eid)
					Network.sendSpectateStatus(Global.eid, true)
			return
		elif aliveCount == 1:
			for i in range(12):
				if playerStats[i]["health"] > 0:
					endGame(false, i)
					break
			return
	if id == Global.eid:
		Global.eid = findNewTarget(id, true, true) #seek new target
		if Global.online && !Global.botList[Global.eid]:
			Network.sendStatusRequest(Global.eid)
			if Global.playerDead: Network.sendSpectateStatus(Global.eid, true)
	if id == Global.sid: Global.sid = findNewTarget(id, false, false) #seek new sender
	if Global.online:
		if Global.botList[Global.sid]:
			lastEggBuffer = eggParent.rateBuffer
			eggParent.rateBuffer = 0
		elif lastEggBuffer > eggParent.rateBuffer: eggParent.rateBuffer = lastEggBuffer
	if Global.eid == Global.sid:
		eggParent.botReceive = false
		enemyEggParent.eggTarget = eggParent

func registerHealth(id: int, lastHitId: int, health: int, justSet: bool = false) -> void:
	if aliveCount == 1: return
	health = clamp(health, 0, 5)
	var prevhp = playerStats[id]["health"]
	playerStats[id]["health"] = health
	for i in range(5): heartIcons[offsetIds[id]][i].visible = i < health
	if id == Global.eid:
		if prevhp > health && !justSet: $HitSFX.playSound("hit", randi() % 3)
		for i in range(5): targetHearts[i].visible = i < health
	elif id == Global.id && !Network.lobby:
		if Global.online: player.health = health
		for i in range(5):
			player.heartIcons[i].visible = i < health
			player.heartBGs[i].visible = i >= health
	if health < 1:
		Global.botList[id] = true
		aliveCount -= 1
		if justSet:
			playerStats[id]["health"] = 0
			powerIcons[offsetIds[id]].visible = false
			heartIcons[offsetIds[id]][0].get_parent().visible = false
			if id == Global.eid: targetHearts[0].get_parent().visible = false
			colorPlates[offsetIds[id]].self_modulate.a = .3
			namePlates[offsetIds[id]].self_modulate.a = .5
			nameArrows[offsetIds[id]].visible = false
			return
		var me = Global.id == id
		if me && Network.lobby: return
		var eParent = enemyEggParent if !me else eggParent
		if (me || id == Global.eid) && eParent.slowMo != .5:
			var deathTimer = Timer.new()
			add_child(deathTimer)
			deathTimer.connect("timeout", self, "registerDeath", [id, lastHitId, false, deathTimer])
			deathTimer.start(3)
			eParent.eggTarget = null
			eParent.slowMo = .5
			eParent.set_process(false)
			var chicken = enemy if !me else player
			chicken.idle = true
			if !me && Global.botList[Global.eid]: eParent.player = null
			if Global.online: Global.botList[id] = true
			chicken.speed *= .5
			chicken.get_child(0).texture = deadChicken
			if !me:
				enemyItemParent.player = null
				if !Global.playerDead:
					eggParent.eggQueue = true
					eggParent.eggQueueTime = Global.gameTime
					if !Global.playerDead && (!Global.online || !Network.lobby): enemyArrow.changeSprite('dead')
			else: #set up spectate mode and reset stats
				player.eggCount = 0
				$EggBar.clearEggs()
				player.ResetPowerups()
				if Global.online && !Global.botList[Global.eid]: Network.sendSpectateStatus(Global.eid, true)
				Network.spectated = false
				$PlayerContainer/Viewport/Playspace/ItemParent.player = null
				for i in range(12):
					if i == Global.id: continue
					statusLabels[offsetIds[i]].text = '' if i != Global.eid else '[SPEC]'
		else: registerDeath(id, lastHitId, false, null)

func findNewTarget(id: int, below: bool, eid: bool) -> int:
	var tries = 0
	var newId = null
	while(newId == null && tries < 16):
		if below: id = id + 1 if id + 1 < 12 else 0
		else: id = id - 1 if id - 1 >= 0 else 11
		tries += 1
		if id == Global.id || playerStats[id]["health"] < 1: continue
		if Global.online && Global.playerDead && Global.botList[id]: continue
		newId = id
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
		Network.helper.foundDummy = false
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
	if win || (!win && aliveCount < 2):
		Global.gameOver = true
		gameOverLabels["label"].text = "You won!" if win else playerStats[winner]["name"] + " wins!"
		gameOverLabels["sublabel"].text = "LAID: " + str(confirmedLaid)
		gameOverLabels["sublabel"].text += "  SHELLS: " + str(confirmedShells)
		if recordedTime == null: gameOverLabels["sublabel"].text += "  TIME: " + hud["timer"].text
		else: gameOverLabels["sublabel"].text += "  TIME: " + recordedTime
		if !Global.online: gameOverLabels["subsub"].text = "Press ESC to leave, R to restart"
		else:
			gameOverLabels["subsub"].text = "Winner winner, chicken's dinner"
			if win: Network.sendEndGame()
	else: #spectate / hen house note
		recordedTime = hud["timer"].text
		var lastHit = player.lastHitId
		var textChoices = ["YOU'VE BEEN PLUCKED", "YOU WERE SHELLED", "YOU WERE SCRAMBLED", "YOU GOT CLUCKED",
		"YOU'VE BEEN FRIED", "YOU GOT TURNED INTO TENDIES", "YOU GOT COCK-A-DOODLE-DOO'D", "YOU BECAME A FAMILY MEAL"]
		gameOverLabels["label"].text = textChoices[randi() % len(textChoices)]
		gameOverLabels["sublabel"].text = "BY "
		gameOverLabels["sublabel"].text += playerStats[lastHit]["name"] if lastHit != 99 else "THE CHICKEN GODS"
		if !Global.online:
			gameOverLabels["subsub"].text = "Press Up or Down to change spectate\nPress ESC to leave, R to restart"
		else: gameOverLabels["subsub"].text = "Press Space to go back to the hen house"
		#you are dead settings
		Global.playerDead = true
		if Global.botList[Global.sid]: enemyEggParent.rateBuffer *= .1

func makeBot() -> void:
	botIsSpawned = true
	$EnemyContainer/Viewport.add_child(enemySpace.instance())
	enemyBG.modulate = playerStats[Global.eid]["color"]
	enemyBorder.modulate = playerStats[Global.eid]["color"]
	enemyEggParent = $EnemyContainer/Viewport/Enemyspace/EggParent
	$NetworkHelper.enemyEggParent = enemyEggParent
	enemyItemParent = $EnemyContainer/Viewport/Enemyspace/ItemParent
	$NetworkHelper.enemyItemParent = enemyItemParent
	eggParent.eggTarget = enemyEggParent
#	eggParent.botIsBelow = Global.botList[Global.eid]# && !Global.activeList[Global.eid]
	if Global.botList[Global.eid]:# && !Global.activeList[Global.eid]:
		var chick = chickenBot.instance()
		$EnemyContainer/Viewport/Enemyspace.add_child(chick)
		enemy = $EnemyContainer/Viewport/Enemyspace/ChickenBot
		enemy.position = Vector2(rand_range(Global.botBounds.x+10, Global.botBounds.y-10),
		enemy.position.y + rand_range(-20,20))
		var eggRoll = randi() % 100 + 1
		if eggRoll < 75: eggRoll = round(rand_range(0,5))
		else: eggRoll = round(rand_range(5,20))
		enemy.eggCount = eggRoll
		if eggRoll - 1 > 0: for i in range(eggRoll-1): enemy.eggs[i] = 'normal'
		enemy.scale = Vector2(enemy.baseScale.x + (.05 * eggRoll), enemy.baseScale.y + (.05 * eggRoll))
		enemy.baseSpriteScale = enemy.sprite.scale
		enemy.weight = enemy.baseWeight + (eggRoll * .0002)
		#make fake velocity
		var rnd = [-1,1]
		for i in range(len(enemy.dirListx)):
			enemy.dirListx[i] = rnd[randi() % 2]
			enemy.dirListy[i] = rnd[randi() % 2]
		#make fake eggs
		enemyEggParent.botEggCount = eggRoll
		var myEnemy = findNewTarget(Global.eid, false, false)
		if Global.sid == Global.eid:
			enemyEggParent.eggTarget = eggParent
			eggParent.botReceive = false
		var chickenY = enemy.position.y
		var yroll
		for _i in range(rand_range(2 + (1 * Global.level), 8 + (3 * Global.level))):
			yroll = round(rand_range(10,720))
			while yroll < chickenY + 10 && yroll > chickenY - 10: yroll = round(rand_range(10,720))
			enemyEggParent.makeEgg(99, enemyEggParent.randType(Global.normalcy),
			Vector2(rand_range(Global.botBounds.x, Global.botBounds.y), yroll))
	else:
		var chick = chickenDummy.instance()
		$EnemyContainer/Viewport/Enemyspace.add_child(chick)
		enemy = $EnemyContainer/Viewport/Enemyspace/ChickenBot
		var scl = float(targetPlayerLoad["scale"])
		chick.scale = Vector2(scl, scl)
		chick.position = Vector2(float(targetPlayerLoad["x"]), float(targetPlayerLoad["y"])) * .5
		chick.onlineIdle = Network.idleList[Global.eid]
		eggParent.onlineTargetIdle = Network.idleList[Global.eid]
	enemy.health = playerStats[Global.eid]["health"]
	targetHearts[0].get_parent().visible = true
	for i in range(5): targetHearts[i].visible = i < enemy.health
	$NetworkHelper.enemy = enemy
	enemyItemParent.player = enemy
	enemyEggParent.player = enemy
	enemy.id = Global.eid
	enemyEggParent.myid = Global.eid
	if !Global.playerDead && (!Global.online || !Network.lobby):
		enemyArrow.changeColor(Global.eid)
		enemyArrow.changeSprite('normal')

func calculategameTime() -> String:
	var lev = Global.level
	var timeBase = 80 - (Global.difficulty * 20)
	Global.level = clamp(floor(Global.gameTime / timeBase), 0, 5)
	timerBar.value = (((Global.gameTime - (timeBase * Global.level)) / timeBase) * 100) + 1
	if lev != Global.level:
		$PlayerContainer/Viewport/Playspace/ItemParent.powerCooldown = 120 - (Global.level * 7)
		enemyItemParent.powerCooldown = 120 - (Global.level * 7)
		eggParent.eggRateLevelStr = str(Global.level)
		hud["level"].text = str(Global.level+1)
		enemyEggParent.eggRateLevelStr = str(Global.level)
		if Global.level > 0:
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
	var mins = int(Global.gameTime) / 60
	var secs = int(Global.gameTime - (mins * 60))
	mins = "0" + str(mins) if mins < 10 else str(mins)
	var timerr = mins + ":"
	timerr += str(secs) if secs > 9 else "0" + str(secs)
	return timerr

func setPowerupIcon(id: int, type: String) -> void:
	if type == "": powerIcons[offsetIds[id]].visible = false
	elif type in powerups:
		powerIcons[offsetIds[id]].visible = true
		powerIcons[offsetIds[id]].texture = powerups[type]

func setNameplateName(id: int) -> void:
	namePlates[offsetIds[id]].text = Global.nameMap[id] if Global.nameMap[id] != null else Global.botNameMap[id] + '[bot]'
