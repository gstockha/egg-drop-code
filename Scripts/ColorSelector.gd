extends GridContainer
var Swatch = preload("res://Scenes/UI/ColorSwatch.tscn")
var preferedColorId = 5
var swatches = []
var prev = 5

func _ready():
	var cid = 0
	for color in Global.colorIdMap:
		var swatch = Swatch.instance()
		swatch.modulate = color
		add_child(swatch)
		swatches.append(swatch)
		swatch.connect("button_down", self,
		"_on_ColorSwatch_pressed", [cid])
		cid += 1
	prev = Global.id
	swatches[Global.id].highLight(true)

func _on_ColorSwatch_pressed(cid: int) -> void:
	Global.id = cid
	Global.prefID = cid
	swatches[prev].highLight(false)
	swatches[cid].highLight(true)
	prev = cid
	get_parent().self_modulate = Global.colorIdMap[cid]
