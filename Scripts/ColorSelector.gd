extends GridContainer
var Swatch = preload("res://Scenes/UI/ColorSwatch.tscn")
var preferedColorId = 5
onready var nameLabel = get_node("../../NameLabel")

func _ready():
	var cid = 0
	for color in Global.colorIdMap:
		var swatch = Swatch.instance()
		swatch.modulate = color
		add_child(swatch)
		swatch.connect("button_down", self,
		"_on_ColorSwatch_pressed", [cid])
		cid += 1

func _on_ColorSwatch_pressed(cid: int) -> void:
	Global.id = cid
	nameLabel.self_modulate = Global.colorIdMap[cid]