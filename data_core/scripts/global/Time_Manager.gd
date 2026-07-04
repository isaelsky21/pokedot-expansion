extends Node
class_name TiempoManager

enum TimeOfDay { MORNING, DAY, DUSK, NIGHT }

var current_hour: int = 0
var current_time_state: TimeOfDay = TimeOfDay.DAY
var is_indoors: bool = false

# 🎨 COLORES: SIN ALFA (a=1.0), solo tono
const COLOR_MORNING = Color(1.08, 1.02, 0.90, 1.0)   # Blanco cálido
const COLOR_DAY     = Color(1.00, 1.00, 1.00, 1.0)   # Normal
const COLOR_DUSK    = Color(1.12, 0.592, 0.456, 1.0)   # Tono naranja
const COLOR_NIGHT   = Color(0.52, 0.579, 1.1, 1.0)   # Tono azul oscuro

@onready var canvas_modulate: CanvasModulate = $CanvasModulate


func _ready():
	if not canvas_modulate:
		canvas_modulate = CanvasModulate.new()
		canvas_modulate.name = "CanvasModulate"
		add_child(canvas_modulate)

	_read_system_time()
	_apply_state(true)


func _process(delta: float) -> void:
	_read_system_time()
	_smooth_transition(delta)


func _read_system_time() -> void:
	var now = Time.get_datetime_dict_from_system()
	current_hour = now.hour

	var new_state = _get_state(current_hour)
	if new_state != current_time_state:
		current_time_state = new_state
		print("⏱️ Cambio horario → ", TimeOfDay.keys()[int(current_time_state)])


func _get_state(h: int) -> TimeOfDay:
	if h >= 4  and h < 10: return TimeOfDay.MORNING
	if h >= 10 and h < 19: return TimeOfDay.DAY
	if h >= 19 and h < 21: return TimeOfDay.DUSK
	return TimeOfDay.NIGHT


func _smooth_transition(delta: float) -> void:
	if is_indoors:
		canvas_modulate.color = COLOR_DAY
		return

	var target: Color
	match current_time_state:
		TimeOfDay.MORNING: target = COLOR_MORNING
		TimeOfDay.DAY:     target = COLOR_DAY
		TimeOfDay.DUSK:    target = COLOR_DUSK
		TimeOfDay.NIGHT:   target = COLOR_NIGHT

	# Mezcla suave, siempre opaco
	canvas_modulate.color = canvas_modulate.color.lerp(target, delta * 0.5)


func _apply_state(instant: bool = false) -> void:
	if is_indoors:
		canvas_modulate.color = COLOR_DAY
		return

	var target: Color
	match current_time_state:
		TimeOfDay.MORNING: target = COLOR_MORNING
		TimeOfDay.DAY:     target = COLOR_DAY
		TimeOfDay.DUSK:    target = COLOR_DUSK
		TimeOfDay.NIGHT:   target = COLOR_NIGHT

	if instant:
		canvas_modulate.color = target


func set_indoors(indoors: bool) -> void:
	is_indoors = indoors
	print("🏠 Interior:", indoors)
	_apply_state(true)
