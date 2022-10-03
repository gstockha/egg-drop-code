extends Control

var colorPlates = []
var namePlates = []
var nameArrows = []
var statusLabels = []
var playerStats = []
var barKeys = []
var enemySpace = preload("res://Scenes/Enemyspace.tscn")
onready var playerBG = get_node("PlayerBG")
onready var enemyBG = get_node("EnemyBG")

func _ready():
	for i in range(1,13):
		if (i < 7):
			colorPlates.append(get_node("NamePlates/ScoresTop/NamePlate" + str(i)))
			namePlates.append(get_node("NamePlates/ScoresTop/NamePlate" + str(i) + "/Name"))
			statusLabels.append(get_node("NamePlates/ScoresTop/NamePlate" + str(i) + "/StatusLabel"))
		else:
			colorPlates.append(get_node("NamePlates/ScoresBottom/NamePlate" + str(i-6)))
			namePlates.append(get_node("NamePlates/ScoresBottom/NamePlate" + str(i-6) + "/Name"))
			statusLabels.append(get_node("NamePlates/ScoresBottom/NamePlate" + str(i-6) + "/StatusLabel"))
	nameArrows = get_node("NamePlates/Arrows").get_children()
	for i in range(12):
		playerStats.append({"id" : i, "name": Global.botNameMap[i], "color": Global.colorIdMap[i], "health": 6})
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

func registerDeath(id: int, lastHitId: int, disconnect: bool) -> void:
	playerStats[id]["health"] = 0
	var enemyDeath = id == Global.eid
	if enemyDeath:
#		$Enemyspace.queue_free()
#		add_child(enemySpace.instance())
		var start = Global.eid + 1 if Global.eid + 1 < 12 else 0
		var tries = 0
		for i in range(start, 12):
			if playerStats[i]["health"] >= 1 && i != Global.id:
				Global.eid = i
				break
			if i == 11: i = -1
			tries += 1
			if tries > 11: break
	if id != Global.eid || !enemyDeath: redrawNameplates()
	else:
		print("You win!")
		Global.victory = true

func redrawNameplates() -> void:
	var upperOrder = []
	var lowerOrder = []
	var idOrder = []
	var list = []
	var targId = null
	for i in range(12):
		if playerStats[i]["health"] < 1:
			if i < 6: upperOrder.append(i)
			else: lowerOrder.append(i)
		else:
			if targId == null: targId = i
			idOrder.append(i)
	for i in range(len(upperOrder)): list.append(upperOrder[i])
	for i in range(len(idOrder)): list.append(idOrder[i])
	for i in range(len(lowerOrder)): list.append(lowerOrder[i])
	for i in range(12):
		colorPlates[i].self_modulate = Global.colorIdMap[list[i]]
		namePlates[i].text = Global.botNameMap[list[i]]
		nameArrows[i].self_modulate = Global.colorIdMap[list[i]]
		if playerStats[list[i]]["health"] < 1:
			colorPlates[i].self_modulate.a = .5
			nameArrows[i].self_modulate.a = 0
		else:
			colorPlates[i].self_modulate.a = 1
			nameArrows[i].self_modulate.a = 1
	if targId != null && colorPlates[6].self_modulate != playerStats[Global.eid]["color"]:
		if targId != Global.sid:
			colorPlates[targId].self_modulate = colorPlates[6].self_modulate
			namePlates[targId].text = namePlates[6].text
			nameArrows[targId].self_modulate = nameArrows[6].self_modulate
		colorPlates[6].self_modulate = playerStats[Global.eid]["color"]
		namePlates[6].text = playerStats[Global.eid]["name"]
		nameArrows[6].self_modulate = playerStats[Global.eid]["color"]
