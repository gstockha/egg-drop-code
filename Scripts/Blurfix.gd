extends ViewportContainer

func _ready():
	$Viewport.get_texture().flags = Texture.FLAG_FILTER
