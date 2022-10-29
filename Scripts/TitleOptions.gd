extends Control
export var title = true
onready var sfxSlider = $SoundsLabel/SoundSlider
onready var musicSlider = $MusicLabel/MusicSlider
var lastSfxValue = 0
var lastMusicValue = 0
var focused = false
onready var muteBtn = get_node("../MuteButton")
onready var mstr = AudioServer.get_bus_index("Master")

func _ready():
	focused = !title #strange little disablement so when we back out to main menu we don't press START immediately
	muteBtn.self_modulate.a = .6 if Global.muted else 1
	sfxSlider.value = AudioServer.get_bus_volume_db(mstr) * 5

func _input(event):
	if event.is_action_pressed("fullscreen"): OS.window_fullscreen = !OS.window_fullscreen
	elif event.is_action_pressed("menu"):
		if title: return
		if !visible:
			visible = true
			$MainButton.grab_focus()
		else: visible = false
		Global.menu = !Global.menu
		if !Global.online && !Global.countdown:
			get_tree().paused = !get_tree().paused
	elif event.is_action_pressed("ui_accept"):
		if musicSlider.has_focus():
#			if musicSlider.value > -100:
#				lastMusicValue = musicSlider.value
#				musicSlider.value = -100
#			else: musicSlider.value = lastMusicValue
			pass
		elif sfxSlider.has_focus():
			if sfxSlider.value > -100:
				lastSfxValue = sfxSlider.value
				sfxSlider.value = -100
			else: sfxSlider.value = lastSfxValue
	elif focused: return
	if event.is_action_pressed("ui_down") || event.is_action_pressed("ui_up"):
		focused = true
		if event.is_action("ui_down"): #CHANGE THESE WHEN ENABLING MORE BUTTONS
			if title: $SoundsLabel/SoundSlider.grab_focus()
			else :$ExitButton.grab_focus()
		else: $SoundsLabel/SoundSlider.grab_focus()

func _on_MainButton_button_up(): #solo game / continue
	if title:
		Global.online = false
		visible = false
		get_node("../PlayerOptions").visible = true
		get_node("../PlayerOptions/NameLabel/NameEdit").grab_focus()
	else: #in-game CONTINUE
		if !Global.online && !Global.countdown: get_tree().paused = false
		visible = false
		Global.menu = false

func _on_ExitButton_button_down():
	if title: get_tree().quit()
	else:
		Global.defaults()
		get_tree().paused = false
		get_tree().change_scene("res://Scenes/Screens/TitleScreen.tscn")

func _on_MenuButton_button_down(): #in-game menu btn
	if visible || title: return
	visible = true
	Global.menu = true
	if !Global.online && !Global.countdown:
		get_tree().paused = true

func _on_FullscreenButton_button_up():
	OS.window_fullscreen = !OS.window_fullscreen

func _on_SoundSlider_focus_entered():
	$SoundsLabel.self_modulate = Color('faff3e')

func _on_SoundSlider_focus_exited():
	$SoundsLabel.self_modulate = Color.white

func _on_MusicSlider_focus_entered():
	$MusicLabel.self_modulate = Color('faff3e')

func _on_MusicSlider_focus_exited():
	$MusicLabel.self_modulate = Color.white

func _on_MuteButton_button_down():
	Global.muted = !Global.muted
	AudioServer.set_bus_mute(mstr, Global.muted)
	muteBtn.self_modulate.a = .6 if Global.muted else 1

func _on_SoundSlider_value_changed(value):
	if value <= -100:
		AudioServer.set_bus_volume_db(mstr, -80)
		return
	AudioServer.set_bus_volume_db(mstr, value * .2)

func _on_OnlineButton_button_up():
	Global.online = true
	visible = false
	get_node("../PlayerOptions").visible = true
	get_node("../PlayerOptions/NameLabel/NameEdit").grab_focus()

func _on_TitleOptions_visibility_changed():
	if title && visible: focused = false
