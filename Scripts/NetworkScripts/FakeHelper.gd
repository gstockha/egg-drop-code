extends Node2D

var lobbyChickens = []
var foundDummy = true

func removePlayer(_id):
	pass

func addLobbyPlayer(_id):
	pass

func movePlayer(_pos, _vel, _grav, _id, _shoveCounter, _shoveVel, _dir):
	pass

func bumpPlayer(_direction, _dirChange, _id):
	pass

func itemSent(_create, _itemId, _eat, _type):
	pass

func addOnlineItem(_itemId, _category, _type, _position):
	pass

func destroyOnlineItem(_itemId, _eat):
	pass

func setStatus(_id, _powerup, _scale):
	pass

func setHealth(_id, _lastHit, _health, _eggId):
	pass

func warpPlayer(_id):
	pass

func setOnlineLabel(set, timer):
	Network.onlineLabelSet[0] = set
	Network.onlineLabelSet[1] = timer

func setTargetStatus(_scale, _x, _y):
	pass

func setPlayerIdle(id: int, idle: bool) -> void:
	Global.idleList[id] = idle
