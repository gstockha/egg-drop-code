extends Node2D

var eggScene = preload("res://Scenes/Egg.tscn")
var eggTimer = 0
var player = null
var botMode = false
var eggTarget = null
var eggRates = {
	0: [8,12],
	1: [5,9],
	2: [3,6],
	3: [1,3]
}
var eggTypes = {
	"normal": { "speed": 2.5, "size": 1.25, "knockback": 200.0, "damage": 1 },
	"fast": { "speed": 3.2, "size": 1, "knockback": 100.0, "damage": 1 },
	"big": { "speed": 2.0, "size": 2, "knockback": 350.0, "damage": 1 }
}
var lowerBounds = 850
var spawnRange = Vector2.ZERO

func _ready():
	eggTimer = rand_range(eggRates[Global.level][0], eggRates[Global.level][1])
	botMode = get_parent().name == "Enemyspace"
	if !botMode:
		player = get_parent().get_node('Chicken')
		lowerBounds += Global.gameSpaceOffset.y
		spawnRange = Vector2(Global.playerBounds.x+Global.gameSpaceOffset.x,
		Global.playerBounds.y+Global.gameSpaceOffset.y)
		eggTarget = get_node('../../Enemyspace/EggParent')
	else:
		var botOffset = Vector2(Global.gameSpaceOffset.x * .5, Global.gameSpaceOffset.y * .5)
		player = get_parent().get_node('ChickenBot')
		lowerBounds = 435 + botOffset.y
		spawnRange = Vector2(Global.botBounds.x+botOffset.x,Global.botBounds.y+botOffset.y)
		for key in eggTypes:
			eggTypes[key]["speed"] *= .5
			eggTypes[key]["size"] *= .5

func _process(delta):
	eggTimer -= 10 * delta
	if eggTimer < 1:
		eggTimer = rand_range(eggRates[Global.level][0], eggRates[Global.level][1])
		makeEgg(99, randType(Global.normalcy), Vector2(rand_range(spawnRange.x, spawnRange.y), 0))

func _physics_process(_delta):
	for egg in get_children():
		egg.global_position.y += egg.speed
		if egg.global_position.y > lowerBounds:
			if egg.id != 99 && !botMode:
				if eggTarget != null:
					eggTarget.makeEgg(egg.id, egg.type, Vector2.ZERO, egg.global_position.x / spawnRange.y)
#				else: #network
			egg.queue_free()
		
func makeEgg(id: int, type: String, position: Vector2, relativePerc = null):
	if (relativePerc != null): position.x = spawnRange.x + ((spawnRange.y - spawnRange.x) * relativePerc)
	var egg = eggScene.instance()
	var typeKey = eggTypes[type]
	egg.type = type
	egg.size = typeKey["size"]
	egg.scale = Vector2(egg.size, egg.size)
	add_child(egg)
	egg.speed = typeKey["speed"]
	egg.knockback = typeKey["knockback"]
	egg.damage = typeKey["damage"]
	egg.id = id
	egg.global_position = position
	if id != 99:
		egg.sprite.modulate = Global.colorIdMap[id]
		if Global.id == id && !botMode: 
			egg.speed *= 2
#			egg.sprite.modulate.a = .75

func randType(normalcy: int) -> String:
	var roll = randi() % 100 + 1
	if roll <= normalcy: return "normal"
	var remainder = 100 - normalcy
	roll =  remainder - (roll - normalcy)
	if (roll <= remainder * .75): return "fast"
	return "big"
