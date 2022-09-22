extends Control

onready var eggParent = $Eggs
onready var eggIcon = preload("res://Scenes/EggIcon.tscn")
var normalSprite = preload("res://Sprites/Egg.png") #dont use this eventually
onready var eggSprites = {
	"normal": normalSprite, "fast": normalSprite, "big": normalSprite
}
var eggs = []
var player = null

func _ready():
	player = get_node("../Playspace/Chicken")
	eggs.append($Eggs/EggActive)
	var icon
	for i in range(player.maxEggs-1):
		icon = eggIcon.instance()
		eggParent.add_child(icon)
		icon.rect_global_position = Vector2(-75 - (i * 23), -18)
		eggs.append(icon)

func drawEggs(type: String) -> void:
	if type == "": #lose first egg
		for i in range(player.maxEggs):
			if eggs[i+1].texture == null:
				eggs[i].texture = null
				return
			eggs[i].texture = eggs[i+1].texture
	else: eggs[player.eggCount-1].texture = eggSprites[type] # add an egg
