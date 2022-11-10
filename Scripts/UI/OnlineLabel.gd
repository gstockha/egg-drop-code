extends Label
var up = false
var timerOn = false
var timer = 0

func _ready():
	visible = Network.lobby
	set_process(visible)
	if visible && Network.onlineLabelSet[0]:
		text = Network.onlineLabelSet[0]
		timer = Network.onlineLabelSet[1]
		Network.onlineLabelSet[0] = null
		Network.onlineLabelSet[1] = null
		timerOn = timer > 0
		if timerOn: timer -= 1 #boost

func _process(delta):
	if !up:
		modulate.a -= .01
		if modulate.a < .4: up = true
	else:
		modulate.a += .01
		if modulate.a >= 1: up = false
	if timerOn:
		if timer >= 0:
			timer -= delta
			text = 'Starting in ' + str(ceil(timer)) + ' seconds!'
		else:
			timerOn = false
			text = 'Commencing egg drop!'

func _on_OnlineLabel_visibility_changed():
	set_process(visible)
	if visible == false:
		timerOn = false
		text = 'Waiting for new game...'
