extends Node2D

var timer = 3.5
var finished = false
onready var bg = get_node("../CountdownBG")
onready var sfx = get_node("../GameSFX")

func _ready():
	visible = !Network.lobby
	if !visible:
		queue_free()
		return
	$StartTimer.visible = false
#	set_physics_process(!Network.lobby)
	if Network.lobby: return
	get_tree().paused = true
	Global.countdown = true
	bg.visible = true

func _process(delta):
	if Global.menu && !Global.online: return
	timer -= delta
	bg.modulate.a -= delta * .2
	var time = ceil(timer)
	if timer <= 3 && timer > 0 && !finished:
		$StartTimer.visible = true
		$StartTimer.text = str(time)
		var scl = 3 * ((time - timer) / 1)
		scale = Vector2(scl, scl)
	elif timer <= 0 && !finished:
		finished = true
		scale = Vector2(1, 1)
		$StartTimer.text = "EGG DROP!!!"
		sfx.playSound("start")
	elif timer <= -1:
		$StartTimer.visible = false
		get_tree().paused = false
		finished = true
		Global.countdown = false
		bg.visible = false
		bg.queue_free()
		queue_free()
