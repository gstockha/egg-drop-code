extends Node2D

var timer = 3.5
var finished = false

func _ready():
	get_tree().paused = true
	$StartTimer.visible = false
	Global.pausable = false

func _physics_process(delta):
	timer -= delta
	var time = ceil(timer)
	if timer <= 3 && timer > 0 && !finished:
		$StartTimer.visible = true
		$StartTimer.text = str(time)
		var scl = 3 * ((time - timer) / 1)
		print(scl)
		scale = Vector2(scl, scl)
	elif timer <= 0 && !finished:
		finished = true
		scale = Vector2(1, 1)
		$StartTimer.text = "EGG DROP!!!"
	elif timer <= -1:
		$StartTimer.visible = false
		get_tree().paused = false
		Global.pausable = true
		finished = true
		queue_free()
