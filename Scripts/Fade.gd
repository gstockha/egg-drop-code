extends CanvasLayer
var screen = "title"

func _ready():
	if get_parent().name == "Game": transition('fade_to_white')

func transition(anim_name):
	$AnimationPlayer.current_animation = anim_name

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade_to_black" && screen == "title": 
		get_tree().change_scene("res://Scenes/Screens/Game.tscn")
