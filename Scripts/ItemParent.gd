extends Node

var foodTimer = 0
var maxFood = 6
var foodCount = 0
var player = null
onready var items = {
	"food": preload("res://Scenes/Corn.tscn")
}
onready var foodSprites = {
	"corn": preload("res://Sprites/Corn.png")
}

func _ready():
	foodTimer = 30
	player = get_parent().get_node('Chicken')
	print(player)

func _process(delta):
	foodTimer -= 10 * delta
	if foodTimer < 1:
		foodTimer = 50
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

func getLocation() -> Vector2:
	var plrPos = player.global_position
	var upperHalfRoll = ((randi() % 100 + 1) < 75)
	var xx = rand_range(5,955)
	var yy = rand_range(5, 400) if upperHalfRoll else rand_range(400, 755)
	while((xx < plrPos.x + 25 && xx > plrPos.x - 25) || (yy < plrPos.y + 25 && yy > plrPos.y - 25)):
		xx = rand_range(5,955)
		yy = rand_range(5, 400) if upperHalfRoll else rand_range(400, 755)
	return Vector2(xx, yy)
	
func getItemType() -> String: #corn, health, or powerup
	return "food"

func getCornType() -> String:
#	var roll = randi() % 100 + 1
	var type = 'corn'
	return type
