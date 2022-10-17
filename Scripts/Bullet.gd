extends Area2D
var id = null

func _on_Bullet_area_entered(area):
	if id == area.id: return
	queue_free()
	area.hp -= 1
	if area.hp < 1: area.queue_free()
	elif area.hp == 1: area.sprite.texture = Global.crack2
	elif area.hp == 3: area.sprite.texture = Global.crack1
	

func _physics_process(_delta):
	global_position.y -= 10
	if global_position.y <= 8: queue_free()
