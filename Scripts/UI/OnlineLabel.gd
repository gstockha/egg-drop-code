extends Label
var up = false

func _ready():
	visible = Network.lobby
	set_process(visible)

func _process(_delta):
	if !up:
		modulate.a -= .01
		if modulate.a < .4: up = true
	else:
		modulate.a += .01
		if modulate.a >= 1: up = false

func _on_OnlineLabel_visibility_changed():
	set_process(visible)
