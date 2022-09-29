extends Node

var level = 0
var normalcy = 60 #percent chance a normal egg spawns
var id = 5
var eid = 6
var colorIdMap = {
	0: ColorN("violet"), 1: ColorN("palevioletred"), 2: ColorN("palegreen"), 3: ColorN("yellow"),
	4: ColorN("lightsalmon"), 5: ColorN("lightskyblue"), 6: ColorN("lightpink"), 7: ColorN("aquamarine"),
	8: ColorN("orange"), 9: ColorN("tomato"), 10: ColorN("lime"), 11: ColorN("royalblue")
}
var botNameMap = ["BasedMoron", "left_lunch21", "frog", "SunE)))", "xLiNkInXaSsAsSiNx", "You",
"yay ^^ ;3", "Chosen1_One", "agentorange1972", "XiaoKillerCHN#1", "dudelmaaoooo", "DAD"]
var playerBounds = Vector2(0,960)
var botBounds = Vector2(0,480)
