extends CanvasLayer
class_name TransitionManager

var duracion: float = 0.5
var _pantalla: ColorRect


func _ready() -> void:
	# Creamos el nodo de forma automática y segura
	if not has_node("Pantalla"):
		_pantalla = ColorRect.new()
		_pantalla.name = "Pantalla"
		# Configuración para cubrir toda la pantalla
		_pantalla.anchor_left = 0
		_pantalla.anchor_top = 0
		_pantalla.anchor_right = 1
		_pantalla.anchor_bottom = 1
		_pantalla.color = Color(0, 0, 0, 1)  # Negro puro
		_pantalla.modulate.a = 0.0  # Empieza transparente
		_pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pantalla.z_index = 4096
		add_child(_pantalla)
	else:
		_pantalla = $Pantalla

	# Aseguramos que el CanvasLayer esté por encima de todo
	layer = 100
	visible = true


# 🔁 Transición estilo Pokémon: Normal → Negro → Nueva escena → Negro → Normal
func cambiar_escena(ruta_escena: String, tiempo: float = 0.5) -> void:
	duracion = tiempo
	_pantalla.modulate.a = 0.0
	visible = true

	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# 1. Fundido hacia negro
	tween.tween_property(_pantalla, "modulate:a", 1.0, duracion)

	# 2. Cambiar escena mientras está todo negro
	tween.tween_callback(func():
		get_tree().change_scene_to_file(ruta_escena)
	)

	# 3. Fundido de regreso a visible
	tween.tween_property(_pantalla, "modulate:a", 0.0, duracion)

	# 4. Ocultar al terminar
	tween.tween_callback(func():
		visible = false
	)
