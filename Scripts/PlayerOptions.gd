extends Control

onready var nameEdit = $NameLabel/NameEdit
onready var title = get_node("../TitleOptions")
onready var transition = get_node("../Transition")
var default = true
var lastText = ''

func _ready():
	$DifficultyButton.selected = Global.difficulty
	nameEdit.text = Global.playerName
	$PreferredColor.self_modulate = Global.colorIdMap[Global.id]
	lastText = nameEdit.text
	for child in nameEdit.get_children():
		if child is VScrollBar: nameEdit.remove_child(child)
		elif child is HScrollBar: nameEdit.remove_child(child)


func _on_NameEdit_focus_entered():
	$NameLabel.self_modulate = Color('faff3e')
	if !default: return
	default = false
	nameEdit.text = ''

func _on_BackButton_button_up():
	visible = false
	title.visible = true

func _on_BeginButton_button_up():
	if !Global.online:
		Global.playerName = nameEdit.text if nameEdit.text != '' else 'You'
		Global.difficulty = $DifficultyButton.selected
		transition.transition("fade_to_black")
		transition.screen = 'title'
	elif nameEdit.text.length() > 3:
		Global.playerName = nameEdit.text
		$BeginButton.text = "SEARCHING..."
		$BeginButton.disabled = true
		Network.connectToServer()

func _on_DifficultyButton_focus_entered():
	$DifficultyLabel.self_modulate = Color('faff3e')

func _on_DifficultyButton_focus_exited():
	$DifficultyLabel.self_modulate = Color.white

func _on_NameEdit_focus_exited():
	$NameLabel.self_modulate = Color.white
	if nameEdit.text == '':
		nameEdit.text = 'You'
		default = true

func _on_PlayerOptions_visibility_changed():
	$BeginButton.disabled = false
	if visible:
		$DifficultyButton.disabled = Global.online
		if !Global.online:
			$DifficultyLabel.text = 'Difficulty:'
			$DifficultyButton.text = 'Easy'
			$DifficultyButton.rect_position.x = 846
			$BeginButton.text = 'DROP!'
		else:
			$DifficultyLabel.text = 'Skin:'
			$DifficultyButton.text = 'Normal'
			$DifficultyButton.rect_position.x = 770
			_on_NameEdit_text_changed('')

func _on_NameEdit_text_changed(_new_text):
	if !Global.online: return
	if nameEdit.text.length() > 3:
		$BeginButton.text = 'FIND GAME!'
		$BeginButton.disabled = false
	else:
		$BeginButton.text = 'NAME TOO SMALL!'
		$BeginButton.disabled = true
