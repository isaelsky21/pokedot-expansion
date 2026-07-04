extends Node
class_name PlayerManagerNode

var data: PlayerData = PlayerData.new()
var ruta_escena_anterior: String = ""
func new_game(player_name: String):
	data = PlayerData.new()
	data.player_name = player_name
	data.money = 3000
	data.badges = []
	data.flags = {}
	data.items = {"POTION": 5, "POKEBALL": 10}
	data.party = []
	data.current_map_scene = "res://data_core/maps/prado_natal/prado_natal.tscn" # Pon la ruta real
	data.grid_position = Vector2i(7, 10)
	data.direction = Vector2.DOWN

func add_pokemon(pokemon) -> bool:
	if data.party.size() < data.MAX_PARTY:
		data.party.append(pokemon)
		return true
	return false

func remove_pokemon(index: int):
	if index >= 0 and index < data.party.size():
		data.party.remove_at(index)

func add_item(item_id, amount: int = 1):
	var key = str(item_id)
	data.items[key] = data.items.get(key, 0) + amount
