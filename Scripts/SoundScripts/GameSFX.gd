extends AudioController

func _ready():
	sounds = {
		"killconfirm": preload("res://Sounds/chickenDeath.mp3"),
		"start": preload("res://Sounds/roosterStart.mp3"),
		"win": preload("res://Sounds/roosterWin.mp3"),
		"hit": [preload("res://Sounds/ball1.mp3"), preload("res://Sounds/ball2.mp3"), preload("res://Sounds/ball3.mp3")]
	}
