extends Node
class_name SaveManager

const SAVE_FOLDER = "user://saves/"
const SAVE_EXT = ".save"

# Crea la carpeta de guardados
func _ready():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")
		print("✅ Carpeta de guardados lista")

# --- GUARDAR PARTIDA ---
func guardar_partida(ranura: int = 1) -> bool:
	if ranura < 1 or ranura > 3:
		push_warning("Ranura inválida")
		return false

	var ruta = SAVE_FOLDER + "ranura_" + str(ranura) + SAVE_EXT

	# Obtenemos la posición actual de forma segura
	var pos_actual = PlayerManager.data.grid_position

	var datos = {
		"version": "1.0",
		"fecha": Time.get_datetime_string_from_system(),
		"jugador": {
			"nombre": PlayerManager.data.player_name,
			"dinero": PlayerManager.data.money,
			"tiempo_jugado": PlayerManager.data.play_time,
			"mapa": PlayerManager.data.current_map_scene,
			"pos_x": pos_actual.x,
			"pos_y": pos_actual.y,
			"dir_x": PlayerManager.data.direction.x,
			"dir_y": PlayerManager.data.direction.y,
			"medallas": PlayerManager.data.badges,
			"banderas": PlayerManager.data.flags,
			"objetos": PlayerManager.data.items,
			"objetos_clave": PlayerManager.data.key_items
		},
		"equipo": _serializar_equipo(PlayerManager.data.party)
	}

	var archivo = FileAccess.open(ruta, FileAccess.WRITE)
	if not archivo:
		push_error("❌ No se pudo guardar")
		return false

	archivo.store_string(JSON.stringify(datos, "\t"))
	archivo.close()
	print("✅ Partida guardada en ranura", ranura)
	return true

# --- CARGAR PARTIDA ---
func cargar_partida(ranura: int = 1) -> bool:
	if ranura < 1 or ranura > 3:
		push_warning("Ranura inválida")
		return false

	var ruta = SAVE_FOLDER + "ranura_" + str(ranura) + SAVE_EXT
	if not FileAccess.file_exists(ruta):
		push_warning("⚠️ No hay partida guardada")
		return false

	var archivo = FileAccess.open(ruta, FileAccess.READ)
	var contenido = archivo.get_as_text()
	archivo.close()

	var datos = JSON.parse_string(contenido)
	if not datos:
		push_error("❌ Archivo corrupto")
		return false

	# Restauramos datos en PlayerManager
	var j = datos.jugador
	PlayerManager.data.player_name = j.nombre
	PlayerManager.data.money = j.dinero
	PlayerManager.data.play_time = j.tiempo_jugado
	PlayerManager.data.current_map_scene = j.mapa
	PlayerManager.data.grid_position = Vector2i(j.pos_x, j.pos_y)
	PlayerManager.data.direction = Vector2(j.dir_x, j.dir_y)
	PlayerManager.data.badges = j.medallas
	PlayerManager.data.flags = j.banderas
	PlayerManager.data.items = j.objetos
	PlayerManager.data.key_items = j.objetos_clave

	# Restauramos equipo
	PlayerManager.data.party = _deserializar_equipo(datos.equipo)

	print("✅ Partida cargada correctamente")
	return true

# --- Convertir equipo a JSON ---
func _serializar_equipo(equipo: Array) -> Array:
	var lista = []
	for poke in equipo:
		lista.append({
			"especie": poke.species_id,
			"nivel": poke.level,
			"exp": poke.experience,
			"ps": poke.current_hp,
			"estado": poke.status_condition,
			"iv": [poke.iv_hp, poke.iv_attack, poke.iv_defense, poke.iv_speed, poke.iv_sp_attack, poke.iv_sp_defense],
			"naturaleza": poke.nature,
			"movs": poke.moves
		})
	return lista

# --- Convertir de vuelta a objetos Pokemon ---
func _deserializar_equipo(lista: Array) -> Array:
	var equipo = []
	for d in lista:
		var p = Pokemon.new()
		p.species_id = d.especie
		p.level = d.nivel
		p.experience = d.exp
		p.current_hp = d.ps
		p.status_condition = d.estado
		p.iv_hp = d.iv[0]
		p.iv_attack = d.iv[1]
		p.iv_defense = d.iv[2]
		p.iv_speed = d.iv[3]
		p.iv_sp_attack = d.iv[4]
		p.iv_sp_defense = d.iv[5]
		p.nature = d.naturaleza
		p.moves = d.movs
		equipo.append(p)
	return equipo
