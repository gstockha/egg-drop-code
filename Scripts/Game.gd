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
		playerStats.append({"name": Global.botNameMap[i], "color": Global.colorIdMap[i], "health": 6, "barId": i})
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
	if id == Global.eid:
#		$Enemyspace.queue_free()
#		add_child(enemySpace.instance())
		var start = Global.eid + 1 if Global.eid + 1 < 12 else 0
		var tries = 0
		for i in range(start, 12):
			if playerStats[i]["health"] > 0:
				Global.eid = i
				break
			if i == 11: i = 0
			tries += 1
			if tries > 11:
				print("you win!")
				break
	removeNameplate(id)

func removeNameplate(id: int) -> void:
	var targ = id
	if playerStats[id]["barId"] < 6:
		for i in range(Global.id, -1, -1):
			if i == -1 || playerStats[barKeys[i]]["health"] < 1:
				targ = i
				break
			colorPlates[i+1].self_modulate = colorPlates[i].self_modulate
			nameArrows[i+1].self_modulate = nameArrows[i].self_modulate
			namePlates[i+1].text = namePlates[i].text
			barKeys[i+1] = barKeys[i]
			playerStats[barKeys[i]]["barId"] = i + 1
	elif playerStats[id]["barId"] > 6:
		for i in range(7, 12):
			if i + 1 > 11 || playerStats[barKeys[i+1]]["health"] < 1:
				targ = i
				break
			colorPlates[i].self_modulate = colorPlates[i+1].self_modulate
			nameArrows[i].self_modulate = nameArrows[i+1].self_modulate
			namePlates[i].text = namePlates[i+1].text
			barKeys[i] = barKeys[i+1]
			playerStats[barKeys[i+1]]["barId"] = i
	colorPlates[targ].self_modulate = playerStats[id]["color"]
	nameArrows[targ].self_modulate.a = 0
	namePlates[targ].text = playerStats[id]["name"]
	barKeys[targ] = id
	print(barKeys)

