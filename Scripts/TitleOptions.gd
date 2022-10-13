extends Control
export var title = true

func _input(event):
	if event.is_action_pressed("fullscreen"): OS.window_fullscreen = !OS.window_fullscreen
	if event.is_action_pressed("menu"):
		if title: return
		visible = !visible
		Global.menu = !Global.menu
		if !Global.online && !Global.countdown:
			get_tree().paused = !get_tree().paused

func _on_MainButton_button_up():
	if title: get_tree().change_scene("res://Scenes/Game.tscn")
	else: #in-game CONTINUE
		if !Global.online && !Global.countdown: get_tree().paused = false
		visible = false
		Global.menu = false

func _on_ExitButton_button_down():
	if title: get_tree().quit()
	else:
		Global.defaults()
		get_tree().paused = false
		get_tree().change_scene("res://Scenes/TitleScreen.tscn")

func _on_MenuButton_button_down():
	if visible || title: return
	visible = true
	Global.menu = true
	if !Global.online && !Global.countdown:
		get_tree().paused = true
