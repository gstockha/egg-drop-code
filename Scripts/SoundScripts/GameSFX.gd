extends AudioController

func _ready():
	sounds = {
		"killconfirm": preload("res://Sounds/chickenDeath.mp3"),
		"start": preload("res://Sounds/roosterStart.mp3"),
		"win": preload("res://Sounds/roosterWin.mp3")
	}
