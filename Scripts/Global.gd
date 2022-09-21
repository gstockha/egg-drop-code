extends Node

var level = 2
var normalcy = 60 #percent chance a normal egg spawns
var id = 0
var colorIdMap = {
	0: ColorN("lightskyblue"), 1: ColorN("palevioletred"), 2: ColorN("palegreen"), 3: ColorN("yellow"),
	4: ColorN("lightsalmon"), 5: ColorN("violet"), 6: ColorN("aquamarine"), 7: ColorN("tomato"), 8: ColorN("orange"),
	9: ColorN("pink")
}
var gameSpaceOffset = Vector2(16,16)
