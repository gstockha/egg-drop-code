extends Node

var version = "A_1.0"
var online = false
var level = 0
var normalcy = 60 #percent chance a normal egg spawns
var id = 5
var eid = 0
var sid = 0
var colorIdMap = []
var eggColorMap = [Color.red, Color.purple, Color.green, Color.orange, Color.chartreuse, Color.cornflower,
Color.fuchsia, Color.slateblue, Color.orangered, Color.gold, Color.cyan, Color.hotpink]
var nameMap = []
var playerBounds = Vector2(0,960)
var botBounds = Vector2(0,480)
var playerCount = 1
var playerDead = false
var gameOver = false
var win = null
var menu = false
var countdown = false
var playerName = 'You'
var difficulty = 0
var crack1 = preload("res://Sprites/Eggs/EggCrack1.png")
var crack2 = preload("res://Sprites/Eggs/EggCrack2.png")
var muted = false
var botList = []
var activeList = [] #who is actually in game or just in lobby
var botNameMap = ["XiaoCHN#1", "frog", "left_lunch21", "LOGANCRAFT2013", "dudelmaaooo", "[USA]Marine_mike",
"yay^^", "BasedMoron", "agentorange1972", "SunE)))", "xLiNkInNiNjAx", "DAD"]
var prefID = 5
var gameTime = 0

func _ready():
	for _i in range(12):
		botList.append(true)
		nameMap.append(null)
		activeList.append(false)
	if colorIdMap != []: return
	var rgb = [0,0,0]
	colorIdMap.append(Color8(255,100,100))
	for i in range(1,12):
		rgb[0] = 100
		rgb[1] = 100
		rgb[2] = 100
		if i % 3 == 0:
			rgb[0] = 255
			if i == 3:
				rgb[1] += 70
				rgb[0] += 55
			elif i == 6: rgb[2] += 75
			else:
				rgb[1] = 200
				rgb[0] -= 25
		elif i % 2 == 0 && i != 6 && i != 8:
			rgb[1] = 255
			if i == 4: rgb[0] += 75
			elif i == 10:
				rgb[0] = 100
				rgb[2] = 190
		elif i != 8:
			rgb[2] = 255
			if i == 1: rgb[0] += 75
			elif i == 5: rgb[1] += 75
			elif i == 11:
				rgb[0] = 225
				rgb[2] = 205
				rgb[1] += 35
		else:
			rgb[0] = 255
			rgb[1] = 125
		colorIdMap.append(Color8(rgb[0]*1.2, rgb[1]*1.2, rgb[2]*1.2))
	var purple = colorIdMap[1]
	colorIdMap[1] = colorIdMap[2]
	colorIdMap[2] = purple

func arrangeNames() -> void:
	if Global.online: return
	for i in range(12): if botList[i]: nameMap[i] = botNameMap[i]
	botList[id] = false
	nameMap[id] = Global.playerName

func defaults() -> void:
	var wasOnline = Global.online
	online = false
	level = 0
	normalcy = 60 #percent chance a normal egg spawns
	id = 5
	eid = 0
	sid = 0
	nameMap = []
	playerCount = 1
	playerDead = false
	gameOver = false
	win = null
	menu = false
	countdown = false
	botList = []
	activeList = [] #who is actually in game or just in lobby
	gameTime = 0
	# reset = false
	_ready()
	if wasOnline:
		if Network.client: Network.client.disconnect_from_host(1000, "exit")
		Network.defaults()

func getBot(target) -> bool:
	return botList[target]
