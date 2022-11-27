extends Area2D
class_name egg

var speed = 0
var size = 0
var knockback = 0
var id = 99
var damage = 1
var type = ""
var spdBoost = 1
var hp = 1
var eggid = ""
var magic = false
var normalHitDetect = true
var crackSprite = null
onready var sprite = $Sprite
onready var hitBox = $CollisionShape2D
