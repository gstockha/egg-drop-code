extends Control

var colorPlates = []
var namePlates = []
var nameArrows = []
var statusLabels = []
var playerStats = []
var barKeys = []
var heartIcons = []
var enemySpace = preload("res://Scenes/Enemyspace.tscn")
onready var playerBG = get_node("PlayerBG")
onready var enemyBG = get_node("EnemyBG")

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
	heartIcons[id][0].get_parent().visible = false
	colorPlates[id].self_modulate.a = .3
	namePlates[id].self_modulate.a = .5
	nameArrows[id].visible = false
	playerStats[id].visible = false
	statusLabels[id].text = ""
	Global.playerCount -= 1
	if Global.playerCount < 1 && playerStats[Global.id]["health"] > 0: print("you win!")
	elif id == Global.eid:
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
