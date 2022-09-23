extends Node

var itemTimer = 0
var powerTimer = 0
var healthTimer = 0
var powerCooldown = 120
var maxItems = 6
var itemCount = 0
var player = null
var playerHealth = 6
var offset = Vector2.ZERO
var items = {
	"food": preload("res://Scenes/Corn.tscn"),
	"health": preload("res://Scenes/Health.tscn")
}
var foodSprites = {
	"normal": preload("res://Sprites/Corn/Corn.png"), "three": preload("res://Sprites/Corn/Three.png"),
	"fast": preload("res://Sprites/Corn/Fast.png"), "big": preload("res://Sprites/Corn/Big.png"),
}

func _ready():
	itemTimer = 30
	player = get_parent().get_node('Chicken')
	offset = Global.gameSpaceOffset

func _process(delta):
	var tick = 10 * delta
	powerTimer += tick
	healthTimer += tick
	itemTimer -= tick
	if itemTimer < 1:
		itemTimer = 30
		if itemCount == maxItems: return
		var type = getItemType()
		var item = items[type].instance()
		add_child(item)
		item.global_position = getLocation()
		if type == "food":
			item.type = getCornType()
			item.sprite.texture = foodSprites[item.type]
		elif type == "power":
			pass
	for item in get_children():
		item.duration += tick
		if item.duration > 180:
			item.queue_free()
			itemCount -= 1
		elif item.duration > 160:
			item.scale = item.baseScale * (.25 + (((30 - (item.duration - 160)) / 30) * .75))

func getLocation() -> Vector2:
	var plrPos = player.global_position
	var upperHalfRoll = ((randi() % 100 + 1) < 75)
	var xx = rand_range(5+offset.x, 955+offset.y)
	var yy = rand_range(130+offset.x, 550+offset.y) if upperHalfRoll else rand_range(550+offset.x, 755+offset.y)
	while((xx < plrPos.x + 100 && xx > plrPos.x - 100) || (yy < plrPos.y + 100 && yy > plrPos.y - 100)):
		xx = rand_range(5+offset.x, 955+offset.y)
		yy = rand_range(130+offset.x, 550+offset.y) if upperHalfRoll else rand_range(550+offset.x, 755+offset.y)
	return Vector2(xx, yy)
	
func getItemType() -> String: #food, health, or powerup
	var roll = randi() % 100 + 1
	if healthTimer > powerCooldown * .7:
		if playerHealth < 4 && roll <= (50 - (playerHealth * 10)) || playerHealth < 6 && roll <= (20 - (playerHealth * 2)):
			healthTimer = 0
			return "health" #health chance
	if powerTimer > powerCooldown:
		if roll <= 20:
			powerTimer = 0
#			return "power"
	return "food"

func getCornType() -> String:
	var roll = randi() % 100 + 1
	var type = 'normal' if roll < 80 - (Global.level * 20) else 'three'
	return type
