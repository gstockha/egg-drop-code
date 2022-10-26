extends AudioController

func _ready():
	sounds = {
		"hit": [preload("res://Sounds/ball1.mp3"), preload("res://Sounds/ball2.mp3"), preload("res://Sounds/ball3.mp3")]
	}
