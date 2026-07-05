extends Node
class_name DialogoManager

const RUTA_ESCENA: String = "res://scenes/menus/dialogue_box/caja_dialogo.tscn"
const RUTA_TTF: String = "res://pokemon-emerald-pro.ttf" 
const RUTA_SONIDO_AVANCE: String = "res://sfx/se/GUI sel cursor.ogg"
var caja: CanvasLayer
var fondo: Sprite2D
var texto: RichTextLabel
var indicador: Label
var sonido_avance: AudioStreamPlayer

var activo: bool = false
var en_escritura: bool = false
var velocidad: float = 0.04
var lineas: Array[String] = []
var indice_actual: int = 0
var texto_completo: String = ""
var tiempo: float = 0.0


func _ready() -> void:
	var escena = preload(RUTA_ESCENA)
	caja = escena.instantiate()
	add_child(caja)

	fondo = caja.get_node("Fondo")
	texto = fondo.get_node("Texto")
	indicador = fondo.get_node("Indicador")

	sonido_avance = AudioStreamPlayer.new()
	sonido_avance.stream = preload(RUTA_SONIDO_AVANCE)
	sonido_avance.volume_db = 0 # Ajusta volumen si quieres (-10 más bajo, +3 más alto)
	add_child(sonido_avance)

	var fuente_base = preload(RUTA_TTF)
	var fuente_variante = FontVariation.new()
	fuente_variante.base_font = fuente_base
	fuente_variante.set_spacing(TextServer.SPACING_GLYPH, 1)
	texto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	texto.add_theme_font_override("normal_font", fuente_variante)
	texto.add_theme_font_size_override("normal_font_size", 16)
	texto.add_theme_color_override("default_color", Color("282828ff")) # Negro claro
	texto.add_theme_constant_override("line_separation", 1)

	caja.visible = false
	indicador.visible = false


func mostrar(mensajes: Array[String]) -> void:
	if activo: return
	activo = true
	en_escritura = false
	indice_actual = 0
	lineas = mensajes.duplicate()
	caja.visible = true
	indicador.visible = false
	texto.text = ""
	_mostrar_siguiente_linea()


func _mostrar_siguiente_linea() -> void:
	if indice_actual >= lineas.size():
		_cerrar()
		return
	texto_completo = lineas[indice_actual]
	texto.text = ""
	tiempo = 0.0
	en_escritura = true
	indicador.visible = false # Ocultamos flecha mientras escribe


func _process(delta: float) -> void:
	if not activo: return

	if en_escritura:
		tiempo += delta
		var caracteres = min(int(tiempo / velocidad), texto_completo.length())
		texto.text = texto_completo.substr(0, caracteres)

		# Cuando termina de escribir: mostramos flecha
		if caracteres >= texto_completo.length():
			en_escritura = false
			indicador.visible = true
	else:
		# Parpadeo de la flecha cuando ya terminó
		indicador.modulate.a = 0.3 + 0.7 * sin(Time.get_ticks_msec() * 0.015)


func entrada_avanzar() -> void:
	if not activo: return

	if sonido_avance.stream:
		sonido_avance.play()

	if en_escritura:
		# Si pulsa mientras escribe: salta al final
		texto.text = texto_completo
		en_escritura = false
		indicador.visible = true
	else:
		# Si ya terminó: pasa a siguiente línea
		indice_actual += 1
		_mostrar_siguiente_linea()


func _cerrar() -> void:
	activo = false
	caja.visible = false
	texto.text = ""
	indicador.visible = false
