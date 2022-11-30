extends egg
var explosion = preload('res://Scenes/Eggs/Explosion.tscn')
onready var eggParent = get_parent()

func _ready():
	crackSprite = true
	$AudioStreamPlayer.playing = !eggParent.botMode

func _on_Egg_tree_exiting():
	if id == eggParent.myid: return
	var explode = explosion.instance()
	explode.id = id
	explode.botMode = eggParent.botMode
	eggParent.get_parent().call_deferred("add_child",explode)
	if position.y >= eggParent.lowerBounds:
		explode.position = Vector2(position.x, eggParent.lowerBounds - (eggParent.lowerBounds * .1))
	else: explode.position = position
