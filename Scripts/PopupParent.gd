extends Node2D

var popup = preload('res://Scenes/UI/Popup.tscn')
var popupMap = {
"normal": ["+egg", null], "big": ["+bigegg", null], "fast": ["+fastegg", null], "three": ["+3 eggs", null],
"mega": ["+MEGAEGG", null], "health": ["+1 hp", Color.pink], "shield": ["+shield", Color.orchid],
"butter": ["+egg spd", Color.yellow], "gun": ["+gun", Color.lightgreen], "wildcard": ["+wildcard", Color.orange],
"shrink": ["-size", Color.skyblue]
}

func _process(delta):
	for pop in get_children():
		pop.modulate.a -= delta * pop.fade
		if pop.modulate.a < .1:
			pop.queue_free()
			continue
		pop.position.y -= 100 * delta

func makePopup(name: String, pos: Vector2, kill: bool) -> void:
	var pop = popup.instance()
	if !kill:
		pop.get_child(0).text = popupMap[name][0]
		if popupMap[name][1] != null: pop.modulate = popupMap[name][1]
	else:
		pop.get_child(0).text = 'you shelled ' + name + '!'
		pop.fade = .25
		pos.x = clamp(pos.x, 120, 890)
	add_child(pop)
	pop.global_position = pos
