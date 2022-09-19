extends Node2D

var eggScene = preload("res://scenes/Egg.tscn")
var eggTimer = 0
var eggRates = {
	0: [8,12],
	1: [5,9],
	2: [3,6],
	3: [1,3]
}
enum eggNames { NORMAL, FAST, BIG }
var eggTypes = {
	eggNames.NORMAL: { "speed": 2.5, "size": 1.25, "knockback": 600 },
	eggNames.FAST: { "speed": 3.5, "size": 1, "knockback": 500 },
	eggNames.BIG: { "speed": 2, "size": 2, "knockback": 800 }
}

func _ready():
	eggTimer = rand_range(eggRates[Global.level][0], eggRates[Global.level][1])

func _process(delta):
	eggTimer -= 10 * delta
	if eggTimer < 1:
		eggTimer = rand_range(eggRates[Global.level][0], eggRates[Global.level][1])
		var egg = eggScene.instance()
		var type = _randType(Global.normalcy)
		var typeKey = eggTypes[type]
		egg.speed = typeKey["speed"]
		egg.size = typeKey["size"]
		egg.scale = Vector2(egg.size, egg.size)
		egg.knockback = typeKey["knockback"]
		add_child(egg)
		egg.global_position.x = rand_range(5,955)

func _physics_process(_delta):
	for egg in get_children():
		egg.global_position.y += egg.speed
		if egg.global_position.y > 800: egg.queue_free()


func _randType(normalcy: int) -> int:
	var roll = randi() % 100 + 1
	if roll <= normalcy: return 0
	var remainder = 100 - normalcy
	roll =  remainder - (roll - normalcy)
	if (roll <= remainder * .75): return 1
	return 2
