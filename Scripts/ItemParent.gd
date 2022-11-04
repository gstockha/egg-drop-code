extends Node

var botMode = 0
var itemTimer = 0
var powerTimer = 0
var healthTimer = 0
var powerCooldown = 120
var maxItems = 6
var itemCount = 0
var player = null
var playerHealth = 5
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
var pop = null
var onlineEnemy = false
var onlineItems = []
var onlineCount = 0

func _ready():
#	set_process(!Network.lobby)
	itemTimer = 30
	botMode = 1 if get_parent().name == "Enemyspace" else 0
	if botMode == 0:
		player = get_parent().get_node('Chicken')
		spawnRange = Vector2(Global.playerBounds.x+4, Global.playerBounds.y-4)
		ybounds.append(130)
		ybounds.append(550)
		ybounds.append(755)
		pop = get_node("../PopSFX")
	else:
		onlineEnemy = Global.botlist[Global.eid] && Global.online
		player = get_parent().get_node('ChickenBot') if onlineEnemy else get_parent().get_node('ChickenDummy')
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
	if !onlineEnemy: itemTimer -= tick
	if itemTimer < 1:
		itemTimer = 25
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
		if botMode == 1:
			item.scale *= .5
			item.baseScale = item.scale
#			if onlineEnemy:
#				onlineItems.append(item)
#				item.id = onlineCount
#				onlineCount += 1
		elif Global.online: Network.sendItem()
	for item in get_children():
		item.duration += tick
		if item.duration > 180:
			item.queue_free()
			itemCount -= 1
			if pop: pop.play()
			elif onlineEnemy && onlineItems[item.id] != null: onlineItems[item.id] = null
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
	if healthTimer > powerCooldown * (.7 - (.2 * botMode)):
		if (playerHealth < 3 && roll <= (45 - (playerHealth * 15))) || (playerHealth < 5 && roll <= (15 - (playerHealth * 1))):
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
		if roll <= 40 - (Global.level * 10): return "normal"
		return "three"
	if roll <= 85: return "fast"
	return "big"

func spawnGun() -> void:
	var gun = Gun.instance()
	get_parent().add_child(gun)
	gun.plr = player
	gun.id = player.id
	if botMode == 1: gun.scl = .5
	else: gun.audio = true
	player.gun = gun

func addOnlineItem(category: String, type: String, position: Vector2) -> void:
	var item = items[category].instance()
	if category != "health":
		item.type = type
		item.sprite.texture = foodSprites[type] if category == "food" else powerSprites[type]
	item.position = position
	onlineItems.append(item)
	item.id = onlineCount
	onlineCount += 1
	add_child(item)

func deleteOnlineItem(itemId: int, eat: bool):
	if onlineItems[itemId] == null: return
	onlineItems[itemId].queue_free()
	onlineItems[itemId] = null
	if eat: player.Squish(Vector2(player.baseSpriteScale.x * .85, player.baseSpriteScale.y * 1.15))
