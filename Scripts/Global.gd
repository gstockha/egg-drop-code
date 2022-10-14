extends Node

var online = false
var level = 0
var normalcy = 60 #percent chance a normal egg spawns
var id = 5
var eid = 0
var sid = 0
var colorIdMap = []
var eggColorMap = [Color.red, Color.purple, Color.green, Color.orange, Color.chartreuse, Color.cornflower,
Color.fuchsia, Color.slateblue, Color.orangered, Color.gold, Color.cyan, Color.hotpink]
var botNameMap = []
var playerBounds = Vector2(0,960)
var botBounds = Vector2(0,480)
var playerCount = 12
var playerDead = false
var gameOver = false
var win = null
var menu = false
var countdown = false
var playerName = 'You'
var difficulty = 0

func _ready():
	var rgb = [0,0,0]
	colorIdMap.append(Color8(255,100,100))
#	eggColorMap[0] = colorIdMap[0] * 1.5
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

func arrangeNames() -> void:
	botNameMap = ["XiaoKillerCHN#1", "left_lunch21", "frog", "LOGANCRAFT2013", "dudelmaaooo", "[USA] Marine_mike",
	"yay^^", "BasedMoron", "agentorange1972", "SunE)))", "xLiNkInXaSsAsSiNx", "DAD"]
	botNameMap[id] = Global.playerName

func defaults() -> void:
	online = false
	level = 0
	normalcy = 60 #percent chance a normal egg spawns
	id = 0
	eid = 0
	sid = 0
	playerCount = 12
	playerDead = false
	gameOver = false
	win = null
	menu = false
	countdown = false
	difficulty = 0
