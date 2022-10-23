extends AudioController

func _ready():
	sounds = {
		"splat": preload("res://Sounds/splat.mp3"),
		"power": preload("res://Sounds/metashift.mp3"),
		"healing": preload("res://Sounds/healing.mp3"),
		"butter": preload("res://Sounds/birdpoop.mp3"),
		"pop": preload("res://Sounds/pop2.mp3")
	}
