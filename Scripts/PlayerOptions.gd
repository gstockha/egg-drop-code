extends Control

onready var nameEdit = $NameLabel/NameEdit
onready var difficultyButton = $DifficultyLabel/DifficultyButton
onready var title = get_node("../TitleOptions")
onready var transition = get_node("../Transition")
var default = true
var lastText = ''

func _ready():
	difficultyButton.selected = Global.difficulty
	nameEdit.text = Global.playerName
	nameEdit.get_parent().self_modulate = Global.colorIdMap[Global.id]
	lastText = nameEdit.text
	for child in nameEdit.get_children():
		if child is VScrollBar:
			nameEdit.remove_child(child)
		elif child is HScrollBar:
			nameEdit.remove_child(child)

func _on_NameEdit_text_changed():
	if nameEdit.text.length() > 12: nameEdit.text = lastText
	else: lastText = nameEdit.text

func _on_NameEdit_focus_entered():
	if !default: return
	default = false
	nameEdit.text = ''

func _on_BackButton_button_up():
	visible = false
	title.visible = true

func _on_BeginButton_button_up():
	Global.playerName = nameEdit.text if nameEdit.text != '' else 'You'
	Global.difficulty = difficultyButton.selected
	transition.transition("fade_to_black")
	transition.screen = 'title'
