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
var spawnRange = null
var ybounds = []
var adj = 100
var Gun = preload("res://Scenes/CornGun.tscn")
var items = {
	"food": preload("res://Scenes/Corn.tscn"), "health": preload("res://Scenes/Health.tscn"),
	"power": preload("res://Scenes/Powerup.tscn")
}
var foodSprites = {
	"normal": preload("res://Sprites/Corn/Corn.png"), "three": preload("res://Sprites/Corn/Three.png"),
	"fast": preload("res://Sprites/Corn/Fast.png"), "big": preload("res://Sprites/Corn/Big.png"),
}
var powerSprites = {
	"shield": preload("res://Sprites/Items/ShieldItem.png"), "butter": preload("res://Sprites/Items/Butter.png"),
	"gun": preload("res://Sprites/Items/CornGun.png"), "shrink": preload("res://Sprites/Items/Shrink.png"),
	"wildcard": preload("res://Sprites/Items/Wildcard.png")
}

func _ready():
	itemTimer = 30
	botMode = get_parent().name == "Enemyspace"
	if !botMode:
		player = get_parent().get_node('Chicken')
		spawnRange = Vector2(Global.playerBounds.x+4, Global.playerBounds.y-4)
		ybounds.append(130)
		ybounds.append(550)
		ybounds.append(755)
	else:
		player = get_parent().get_node('ChickenBot')
		spawnRange = Vector2(Global.botBounds.x+2, Global.botBounds.y-2)
		ybounds.append(65)
		ybounds.append(225)
		ybounds.append(377.5)
		adj = 50

func _process(delta):
	if player == null: return
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
		item.position = getLocation()
		if type == "food":
			item.type = getCornType()
			item.sprite.texture = foodSprites[item.type]
		elif type == "power":
			itemTimer -= 15
			item.type = getPowerType()
			item.sprite.texture = powerSprites[item.type]
			item.scale *= 2
			item.baseScale = item.scale
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
	var plrPos = player.position
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
		if (playerHealth < 4 && roll <= (45 - (playerHealth * 12))) || (playerHealth < 6 && roll <= (15 - (playerHealth * 1))):
			healthTimer = 0
			return "health" #health chance
	if powerTimer > powerCooldown:
		if roll <= 20:
			powerTimer = 0
			return "power"
	return "food"

func getPowerType() -> String:
	var roll = randi() % 100 + 1
	if roll <= 5 + (Global.level * 2): return "wildcard"
	if roll <= 20 + (Global.level * 2): return "shield"
	if roll <= 40 + Global.level: return "shrink"
	if roll <= 70: return "butter"
	return "gun"

func getCornType() -> String:
	var roll = randi() % 100 + 1
	if roll <= 60:
		if roll <= 45 - (Global.level * 5): return "normal"
		return "three"
	if roll <= 85: return "fast"
	return "big"

func spawnGun() -> void:
	var gun = Gun.instance()
	get_parent().add_child(gun)
	gun.plr = player
	gun.id = player.id
	if botMode: gun.scl = .5
	player.gun = gun
