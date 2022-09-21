extends Node

var itemTimer = 0
var maxFood = 6
var foodCount = 0
var player = null
var playerHealth = 3
onready var items = {
	"food": preload("res://Scenes/Corn.tscn")
}
onready var foodSprites = {
	"normal": preload("res://Sprites/Corn.png")
}

func _ready():
	itemTimer = 30
	player = get_parent().get_node('Chicken')

func _process(delta):
	var tick = 10 * delta
	itemTimer -= tick
	if itemTimer < 1:
		itemTimer = 50
		if foodCount == maxFood: return
		var type = getItemType()
		var food = items[type].instance()
		add_child(food)
		food.global_position = getLocation()
		if type == "food":
			food.type = getCornType()
			food.sprite.texture = foodSprites[food.type]
		elif type == "powerup":
			pass
	for item in get_children():
		item.duration += tick
		if item.duration > 180: item.queue_free()
		elif item.duration > 160:
			item.scale = item.baseScale * (.25 + (((30 - (item.duration - 160)) / 30) * .75))

func getLocation() -> Vector2:
	var plrPos = player.global_position
	var upperHalfRoll = ((randi() % 100 + 1) < 75)
	var xx = rand_range(5,955)
	var yy = rand_range(100, 500) if upperHalfRoll else rand_range(500, 755)
	while((xx < plrPos.x + 100 && xx > plrPos.x - 100) || (yy < plrPos.y + 100 && yy > plrPos.y - 100)):
		xx = rand_range(5,955)
		yy = rand_range(100, 500) if upperHalfRoll else rand_range(500, 755)
	return Vector2(xx, yy)
	
func getItemType() -> String: #corn, health, or powerup
	return "food"

func getCornType() -> String:
#	var roll = randi() % 100 + 1
	var type = 'normal'
	return type
