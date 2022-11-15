extends ViewportContainer

func _ready():
	$Viewport.get_texture().flags = Texture.FLAG_FILTER

func disableInput(disable: bool):
	$Viewport.gui_disable_input = disable
