extends Resource
class_name DistractionResource

@export var name: String = ""
@export var beforeActiveSprite: Texture2D
@export var afterActiveSprite: Texture2D
@export var grabbingSprite: Texture2D
@export var beforeActiveSfxName: String = ""
@export var afterActiveSfxName: String = ""
@export var grabbingSfxName: String = ""
@export var pickupSfxName: String = ""
@export var durationBeforeActive: float = 2.0
@export_range(0.0, 100.0, 0.1) var spawnChancePercent: float = 100.0
@export var scaleFactor: float = 1.0
@export var beforeActiveScaleFactor: float = 1.0
@export var afterActiveScaleFactor: float = 1.0
@export var grabbingScaleFactor: float = 1.0
