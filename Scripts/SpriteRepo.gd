extends Node

var foodSprites = {
	"normal": preload("res://Sprites/Corn/Corn.png"), "three": preload("res://Sprites/Corn/Three.png"),
	"fast": preload("res://Sprites/Corn/Fast.png"), "big": preload("res://Sprites/Corn/Big.png"),
	"mega": preload("res://Sprites/Corn/Mega.png"), "sniper": preload("res://Sprites/Corn/Sniper.png"),
	"0left": preload("res://Sprites/Corn/Left.png"), "0right": preload("res://Sprites/Corn/Right.png")
}
var powerSprites = {
	"shield": preload("res://Sprites/Items/ShieldItem.png"), "butter": preload("res://Sprites/Items/Butter.png"),
	"gun": preload("res://Sprites/Items/CornGun.png"), "shrink": preload("res://Sprites/Items/Shrink.png"),
	"wildcard": preload("res://Sprites/Items/Wildcard.png")
}
var eggBarSprites = {
	"normal": preload("res://Sprites/Eggs/Egg.png"), "fast": preload("res://Sprites/Eggs/FastEgg.png"),
	"big": preload("res://Sprites/Eggs/BigEgg.png"), "mega": preload("res://Sprites/Eggs/MegaEgg.png"),
	"sniper": preload("res://Sprites/Eggs/SniperEgg.png"), "0right": preload("res://Sprites/Eggs/RightEgg.png"),
	"0left": preload("res://Sprites/Eggs/LeftEgg.png")
}
var crack1 = preload("res://Sprites/Eggs/EggCrack1.png")
var crack2 = preload("res://Sprites/Eggs/EggCrack2.png")
