extends Area2D
var damage = 2
var maxScale = 5
var knockback = 1000.0
var id = 99
var botMode = false
var botReduce = 1
var dissipate = false

func _ready():
	if botMode: botReduce = .5
	get_parent().screenShake(knockback)
	$AudioStreamPlayer.playing = !botMode

func _process(delta):
	scale.x += delta * (5 * botReduce)
	scale.y = scale.x
	if !dissipate && scale.x >= (10 * botReduce): dissipate = true
	elif dissipate:
		modulate.a -= delta * 2.5
		if modulate.a < .1: queue_free()

func _on_Explosion_area_entered(area):
	var type = area.get_groups()
	if type[0] == 'eggs': area.queue_free()
