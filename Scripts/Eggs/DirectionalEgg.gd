extends egg
var direction = 0
var yy = 0
onready var slowMo = get_parent().slowMo

func _ready():
	if get_parent().myid == id:
		set_physics_process(false)
		return
	normalHitDetect = false
	direction = -1 if type == "0left" else 1
	yy = position.y

func _physics_process(_delta):
	position.y = yy
	position.x += speed * slowMo * direction
