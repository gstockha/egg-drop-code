extends Control

onready var eggParent = $Eggs
onready var eggIcon = preload("res://Scenes/UI/EggIcon.tscn")
var hearts = []
var eggSprites = {
	"normal": preload("res://Sprites/Eggs/Egg.png"), "fast": preload("res://Sprites/Eggs/FastEgg.png"),
	"big": preload("res://Sprites/Eggs/BigEgg.png")
}
var eggs = []
var player = null
var cooldown = 0
var oddUp = false
var eggActiveCoords = []
var eggBarCoords = []
var heartCoords = []

func _ready():
	player = get_node("../PlayerContainer/Viewport/Playspace/Chicken")
	eggs.append($Eggs/EggActive)
	eggActiveCoords = [eggs[0].rect_position.y - 1, eggs[0].rect_position.y + 1]
	var icon
	for i in range(player.maxEggs-1):
		icon = eggIcon.instance()
		eggParent.add_child(icon)
		icon.rect_global_position = Vector2(-90 - (i * 23), -22)
		eggs.append(icon)
	eggBarCoords = [icon.rect_position.y - .7, icon.rect_position.y + .7]
	for i in range(5): hearts.append(get_node("../Hearts/HeartIcon" + str(i+1)))
	heartCoords = [hearts[0].rect_position.y - 1.5, hearts[1].rect_position.y + 1.5]

func _process(_delta):
	cooldown += 1
	if cooldown > 14:
		cooldown = 0
		jiggle()

func drawEggs(type: String) -> void:
	if type == "": #lose first egg
		var maxEggs = player.maxEggs
		for i in range(maxEggs):
			if i + 1 == maxEggs || eggs[i+1].texture == null:
				eggs[i].texture = null
				return
			eggs[i].texture = eggs[i+1].texture
	else: eggs[player.eggCount-1].texture = eggSprites[type] # add an egg

func jiggle() -> void:
	oddUp = !oddUp
	if oddUp:
		eggs[0].rect_position.y = eggActiveCoords[0]
		for i in range(1,30):
			if eggs[i].texture == null: break
			eggs[i].rect_position.y = eggBarCoords[0] if i % 2 == 0 else eggBarCoords[1]
		for i in range(5): hearts[i].rect_position.y = heartCoords[0] if i % 2 == 0 else heartCoords[1]
	else:
		eggs[0].rect_position.y = eggActiveCoords[1]
		for i in range(1,30):
			if eggs[i].texture == null: break
			eggs[i].rect_position.y = eggBarCoords[1] if i % 2 == 0 else eggBarCoords[0]
		for i in range(5): hearts[i].rect_position.y = heartCoords[1] if i % 2 == 0 else heartCoords[0]
