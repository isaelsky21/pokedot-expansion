extends RefCounted
class_name Pokemon

# 🔗 Cambio clave: enlazamos por ID en lugar de guardar toda la estructura
# Así es más ligero, rápido y listo para guardar
@export var species_id: Species.SpeciesId = Species.SpeciesId.SPECIES_NONE

var level: int = 5
var experience: int = 0

var iv_hp: int = 0
var iv_attack: int = 0
var iv_defense: int = 0
var iv_speed: int = 0
var iv_sp_attack: int = 0
var iv_sp_defense: int = 0

var nature: PokemonData.Nature = PokemonData.Nature.NATURE_SERIOUS

var current_hp: int = 0

# 🔹 También ajustamos movimientos a tus IDs, para no guardar estructuras completas
var moves: Array[Moves.MoveId] = []


# Pon esto en el _ready() de tu jugador o en cualquier sitio para probar
func _ready():
	# Crear un Pokémon automáticamente
	var mi_bulba = Pokemon.new()
	mi_bulba.setup_new_pokemon(Species.SpeciesId.SPECIES_BULBASAUR, 10)

	# Ver resultados en consola
	print("=== PRUEBA POKÉMON ===")
	print("Especie:", mi_bulba.get_base_data().species_name)
	print("Nivel:", mi_bulba.level)
	print("PS:", mi_bulba.current_hp, "/", mi_bulba.get_max_hp())
	print("Ataque:", mi_bulba.get_stat("attack"))
	print("Velocidad:", mi_bulba.get_stat("speed"))

	# Agregarlo al equipo para que quede guardado
	PlayerManager.add_pokemon(mi_bulba)
	print("Equipo actual:", PlayerManager.data.party.size(), "Pokémon")

func get_base_data() -> PokemonDataStruct:
	return DataBaseGlobal.pokemons.get(species_id, null)

# Calcula los PS máximos
func get_max_hp() -> int:
	var base = get_base_data().base_hp
	# Fórmula especial para PS
	@warning_ignore("integer_division")
	return ((2 * base + iv_hp) * level) / 100 + level + 10

# Calcula cualquier estadística de daño/defensa/velocidad
func get_stat(stat_type: String) -> int:
	var datos = get_base_data()
	var base = 0
	var iv = 0

	# Seleccionamos los valores según la estadística
	match stat_type:
		"attack":
			base = datos.base_attack
			iv = iv_attack
		"defense":
			base = datos.base_defense
			iv = iv_defense
		"sp_attack":
			base = datos.base_sp_attack
			iv = iv_sp_attack
		"sp_defense":
			base = datos.base_sp_defense
			iv = iv_sp_defense
		"speed":
			base = datos.base_speed
			iv = iv_speed
		_:
			return 0

	# Fórmula estándar para el resto de estadísticas
	var valor = ((2 * base + iv) * level) / 100 + 5

	# Aplicamos el modificador de la naturaleza
	valor = apply_nature_modifier(valor, stat_type)

	return int(valor)

# Aplica el efecto de la naturaleza
func apply_nature_modifier(valor: int, stat_type: String) -> float:
	# Ejemplo: si la naturaleza sube Ataque y baja Defensa
	match nature:
		PokemonData.Nature.NATURE_HARDY: return valor * 1.0
		@warning_ignore("incompatible_ternary")
		PokemonData.Nature.NATURE_LONELY: return valor * 1.1 if stat_type == "attack" else valor * 0.9 if stat_type == "defense" else valor
		@warning_ignore("incompatible_ternary")
		PokemonData.Nature.NATURE_BRAVE: return valor * 1.1 if stat_type == "attack" else valor * 0.9 if stat_type == "speed" else valor
		@warning_ignore("incompatible_ternary")
		PokemonData.Nature.NATURE_ADAMANT: return valor * 1.1 if stat_type == "attack" else valor * 0.9 if stat_type == "sp_attack" else valor
		@warning_ignore("incompatible_ternary")
		PokemonData.Nature.NATURE_NAUGHTY: return valor * 1.1 if stat_type == "attack" else valor * 0.9 if stat_type == "sp_defense" else valor
		# ... puedes agregar el resto de naturalezas igual
		_: return valor * 1.0

func setup_new_pokemon(species: Species.SpeciesId, lvl: int = 5) -> void:
	species_id = species
	level = lvl
	# Generamos IVs aleatorios (0-31)
	iv_hp = randi_range(0, 31)
	iv_attack = randi_range(0, 31)
	iv_defense = randi_range(0, 31)
	iv_speed = randi_range(0, 31)
	iv_sp_attack = randi_range(0, 31)
	iv_sp_defense = randi_range(0, 31)
	# Naturaleza aleatoria
	nature = PokemonData.Nature.values()[randi() % PokemonData.Nature.size()]
	# PS al máximo al nacer
	current_hp = get_max_hp()
