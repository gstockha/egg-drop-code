extends Node2D

var eggScene = preload("res://Scenes/Egg.tscn")
var eggTimer = 0
var eggTypes = {
	"normal": { "speed": 2.5, "size": 1.25 },
	"fast": { "speed": 3.2, "size": 1 },
	"big": { "speed": 2.0, "size": 2 }
}

func _process(delta):
	eggTimer -= 10 * delta
	if eggTimer < 1:
		eggTimer = rand_range(1,4)
		var egg = eggScene.instance()
		add_child(egg)
		var typeMap = eggTypes[randType()]
		egg.scale = Vector2(typeMap["size"], typeMap["size"])
		egg.speed = typeMap["speed"]
		egg.modulate = Global.colorIdMap[randi() % 12]
		egg.position = Vector2(rand_range(10, 1558), 0)

func _physics_process(_delta):
	for egg in get_children():
		egg.position.y += egg.speed
		if egg.position.y > 900: egg.queue_free()

func randType() -> String:
	var roll = randi() % 100 + 1
	if roll <= 50: return "normal"
	if roll <= 80: return "fast"
	return "big"
