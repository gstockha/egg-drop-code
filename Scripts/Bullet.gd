extends Area2D
var id = null

func _on_Bullet_area_entered(area):
	if id == area.id: return
	queue_free()
	area.hp -= 1
	if area.hp < 1: area.queue_free()
	elif area.crackSprite == false:
		if area.hp == 1: area.sprite.texture = SpriteRepo.crack2
		elif area.hp == 3: area.sprite.texture = SpriteRepo.crack1
	else:
		if area.hp == 1: area.sprite.texture = SpriteRepo.crackSprites[area.type][1]
		elif area.hp == 3: area.sprite.texture = SpriteRepo.crackSprites[area.type][0]

func _physics_process(_delta):
	global_position.y -= 10
	if global_position.y <= 8: queue_free()
