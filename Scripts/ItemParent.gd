extends Node

var botMode = false
var itemTimer = 0
var powerTimer = 0
var healthTimer = 0
var powerCooldown = 120
var maxItems = 6
var itemCount = 0
var player = null
var playerHealth = 6
var spawnRange = Vector2(7,953)
var ybounds = []
var adj = 100
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
	botMode = get_parent().name == "Enemyspace"
	if !botMode:
		player = get_parent().get_node('Chicken')
		spawnRange.x += Global.gameSpaceOffset.x
		spawnRange.y += Global.gameSpaceOffset.y
		ybounds.append(130+Global.gameSpaceOffset.x)
		ybounds.append(550+Global.gameSpaceOffset.x)
		ybounds.append(755+Global.gameSpaceOffset.x)
	else:
		player = get_parent().get_node('ChickenBot')
		var offset = Global.gameSpaceOffset * .5
		spawnRange = Vector2(986+offset.x,1469+offset.y)
		ybounds.append(65+Global.gameSpaceOffset.x)
		ybounds.append(225+Global.gameSpaceOffset.x)
		ybounds.append(377.5+Global.gameSpaceOffset.x)
		adj = 50

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
		if botMode:
			item.scale *= .5
			item.baseScale = item.scale
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
	var xx = rand_range(spawnRange.x, spawnRange.y)
	var yy = rand_range(ybounds[0], ybounds[1]) if upperHalfRoll else rand_range(ybounds[1], ybounds[2])
	while((xx < plrPos.x + adj && xx > plrPos.x - adj) || (yy < plrPos.y + adj && yy > plrPos.y - adj)):
		xx = rand_range(spawnRange.x, spawnRange.y)
		yy = rand_range(ybounds[0], ybounds[1]) if upperHalfRoll else rand_range(ybounds[1], ybounds[2])
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
	if roll <= 60:
		if roll <= 45 - (Global.level * 5): return "normal"
		return "three"
	if roll <= 85: return "fast"
	return "big"
