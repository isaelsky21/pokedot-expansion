extends RefCounted
class_name PlayerData

# 🔹 Datos básicos del jugador
@export var player_name: String = ""
@export var money: int = 0
@export var play_time: float = 0.0

# 🔹 Progreso y estado del mundo
@export var current_map_scene: String = "" # Ruta de la escena del mapa actual
@export var grid_position: Vector2i = Vector2i(7, 11) # Coordenada en casillas
@export var direction: Vector2 = Vector2.DOWN

@export var badges: Array[int] = []
@export var flags: Dictionary = {}
@export var items: Dictionary = {}
@export var key_items: Array = []
@export var party: Array = []
const MAX_PARTY = 6

@export var music_volume: float = 1.0
@export var sfx_volume: float = 1.0
@export var text_speed: float = 0.05
