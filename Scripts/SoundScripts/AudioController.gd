extends AudioStreamPlayer
class_name AudioController

var sounds = {}


func playSound(key: String, index = null) -> void:
	if index != null: set_stream(sounds[key][index])
	else: set_stream(sounds[key])
	play()
