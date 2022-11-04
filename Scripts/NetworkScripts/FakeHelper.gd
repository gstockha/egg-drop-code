extends Node2D

func removeLobbyPlayer(id: int) -> void:
	pass

func addLobbyPlayer(id: int) -> void:
	pass

func movePlayer(pos: Vector2, vel: Vector2, grav: String, id: int, shoveCounter = null, shoveVel = null, dir = null):
	pass

func bumpPlayer(direction: String, dirChange: int, id: int):
	pass

func itemSent(create: bool, itemId: int, eat: bool, type):
	pass
