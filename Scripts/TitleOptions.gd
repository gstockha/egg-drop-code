extends Control

func _input(event):
	if event.is_action_pressed("fullscreen"): OS.window_fullscreen = !OS.window_fullscreen

func _on_SoloButton_button_up():
	get_tree().change_scene("res://Scenes/Game.tscn")

func _on_ExitButton_button_down():
	get_tree().quit()
