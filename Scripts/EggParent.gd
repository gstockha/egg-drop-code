extends Node2D

var eggScene = preload("res://scenes/Egg.tscn")
var eggTimer = 0
var player = null
var eggRates = {
	0: [8,12],
	1: [5,9],
	2: [3,6],
	3: [1,3]
}
var eggTypes = {
	"normal": { "speed": 2.5, "size": 1.25, "knockback": 200, "damage": 1 },
	"fast": { "speed": 3.5, "size": 1, "knockback": 100, "damage": 1 },
	"big": { "speed": 2, "size": 2, "knockback": 350, "damage": 1 }
}
var offset = Vector2.ZERO

func _ready():
	eggTimer = rand_range(eggRates[Global.level][0], eggRates[Global.level][1])
	player = get_parent().get_node('Chicken')
	offset = Global.gameSpaceOffset

func _process(delta):
	eggTimer -= 10 * delta
	if eggTimer < 1:
		eggTimer = rand_range(eggRates[Global.level][0], eggRates[Global.level][1])
		makeEgg(99, randType(Global.normalcy), Vector2(rand_range(5+offset.x, 955+offset.y), 0))

func _physics_process(_delta):
	for egg in get_children():
		egg.global_position.y += egg.speed
		if egg.global_position.y > 850 + offset.y: egg.queue_free()
		
func makeEgg(id: int, type: String, position: Vector2):
	var egg = eggScene.instance()
	var typeKey = eggTypes[type]
	egg.speed = typeKey["speed"]
	egg.size = typeKey["size"]
	egg.scale = Vector2(egg.size, egg.size)
	egg.knockback = typeKey["knockback"]
	egg.damage = typeKey["damage"]
	egg.id = id
	add_child(egg)
	egg.global_position = position
	if id != 99:
		egg.sprite.modulate = Global.colorIdMap[id]
		if Global.id == id: 
			egg.speed *= 2
#			egg.sprite.modulate.a = .75

func randType(normalcy: int) -> String:
	var roll = randi() % 100 + 1
	if roll <= normalcy: return "normal"
	var remainder = 100 - normalcy
	roll =  remainder - (roll - normalcy)
	if (roll <= remainder * .75): return "fast"
	return "big"
