extends Node

var online = false
var level = 0
var normalcy = 60 #percent chance a normal egg spawns
var id = 5
var eid = 6
var sid = 4
var colorIdMap = {
	0: ColorN("violet"), 1: ColorN("palevioletred"), 2: ColorN("palegreen"), 3: ColorN("yellow"),
	4: ColorN("lightsalmon"), 5: ColorN("lightskyblue"), 6: ColorN("lightpink"), 7: ColorN("aquamarine"),
	8: ColorN("orange"), 9: ColorN("tomato"), 10: ColorN("lime"), 11: ColorN("royalblue") 
}
var eggColorMap = {}
var botNameMap = ["XiaoKillerCHN#1", "left_lunch21", "frog", "LOGANCRAFT2013", "dudelmaaooo", "You",
"yay^^", "BasedMoron", "agentorange1972", "SunE)))", "xLiNkInXaSsAsSiNx", "DAD"]
var playerBounds = Vector2(0,960)
var botBounds = Vector2(0,480)
var playerCount = 12
var playerDead = false
var gameOver = false
var win = null

func _ready():
	var rgb = [0,0,0]
	colorIdMap[0] = Color8(255,100,100)
	eggColorMap[0] = colorIdMap[0] * 1.5
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
				rgb[1] = 225
				rgb[2] -= 25
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
		colorIdMap[i] = Color8(rgb[0]*1.2, rgb[1]*1.2, rgb[2]*1.2)
		eggColorMap[i] = Color8(rgb[0],rgb[1],rgb[2])
