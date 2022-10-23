extends AudioController

func _ready():
	sounds = {
		"hurt": preload("res://Sounds/chickenHurt.mp3"),
		"boing": preload("res://Sounds/boing1.mp3"),
		"bounce": preload("res://Sounds/bounce.mp3"),
		"bouncebig": preload("res://Sounds/bouncebig.mp3"),
		"boingsmall": preload("res://Sounds/boing2.mp3"),
	}
