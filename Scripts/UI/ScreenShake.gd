extends Node2D
var shake = 0
var botReduce = 1

func _ready():
	botReduce = 1 if name == 'Playspace' else .5
	set_process(false)

func _process(delta):
	var rollx = -1 if randf() < .5 else 1
	var rolly = -1 if randf() < .5 else 1
	global_position = Vector2(0 + (shake * (rollx * botReduce)), 0 + (shake * (rolly * botReduce)))
	shake -= delta * 5
	if shake < 1:
		global_position = Vector2(0,0)
		set_process(false)

func screenShake(intensity: float):
	set_process(true)
	shake = intensity * .01
