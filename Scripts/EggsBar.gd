extends Control

onready var eggParent = $Eggs
onready var eggIcon = preload("res://Scenes/UI/EggIcon.tscn")
var eggSprites = {
	"normal": preload("res://Sprites/Eggs/Egg.png"), "fast": preload("res://Sprites/Eggs/FastEgg.png"),
	"big": preload("res://Sprites/Eggs/BigEgg.png")
}
var eggs = []
var player = null

func _ready():
	player = get_node("../PlayerContainer/Viewport/Playspace/Chicken")
	eggs.append($Eggs/EggActive)
	var icon
	for i in range(player.maxEggs-1):
		icon = eggIcon.instance()
		eggParent.add_child(icon)
		icon.rect_global_position = Vector2(-90 - (i * 23), -22)
		eggs.append(icon)

func drawEggs(type: String) -> void:
	if type == "": #lose first egg
		var maxEggs = player.maxEggs
		for i in range(maxEggs):
			if i + 1 == maxEggs || eggs[i+1].texture == null:
				eggs[i].texture = null
				return
			eggs[i].texture = eggs[i+1].texture
	else: eggs[player.eggCount-1].texture = eggSprites[type] # add an egg
