extends Node2D

var cooldown = 0
var right = false
var Bullet = preload("res://Scenes/Bullet.tscn")
var id = null
var scl = 1
var audio = false
var plr = null
onready var par = get_parent()
onready var sfx = $GunSFX

func _physics_process(delta):
	cooldown -= delta
	if cooldown <= 0:
		cooldown = .18
		var bullet = Bullet.instance()
		par.add_child(bullet)
		if right: bullet.global_position.x = plr.global_position.x + 15
		else: bullet.global_position.x = plr.global_position.x - 15
		bullet.global_position.y = plr.global_position.y
		bullet.id = id
		bullet.scale *= scl
		right = !right
		plr.Squish(Vector2(plr.baseSpriteScale.x * 1.3, plr.baseSpriteScale.x * .7))
		if audio:
			sfx.stop()
			sfx.play(0)
