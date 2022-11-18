extends Node2D
var sprites = {
	'dead': preload("res://Sprites/Chickens/DeadChicken.png"),
	'normal': preload("res://Sprites/Chickens/Chicken.png")
}

func _ready():
	visible = !Network.lobby || !Global.online

func changeColor(color: int) -> void:
	$Panel.modulate = Global.colorIdMap[color]

func changeSprite(type: String) -> void:
	if !Network.lobby && !Global.playerDead: visible = true
	$TextureRect.texture = sprites[type]
