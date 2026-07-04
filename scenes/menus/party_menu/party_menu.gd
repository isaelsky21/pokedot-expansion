extends CanvasLayer

@onready var active_panel = $Contenedor/HBoxContainer/ActiveSlot
@onready var sub_party_container = $Contenedor/HBoxContainer/SubPartyList

# Un único temporizador para controlar el ritmo de todos los iconos a la vez
var icon_timer := 0.0
var current_icon_frame := 0

func _ready():
	set_process(true) # Nos aseguramos de que _process esté activo
	cargar_equipo()

func _process(delta):
	icon_timer += delta
	
	# Cada 0.25 segundos cambiamos el frame
	if icon_timer >= 0.25:
		icon_timer = 0.0
		current_icon_frame = 1 - current_icon_frame
		
		# Animamos el slot activo (Izquierda)
		actualizar_frame_slot(active_panel)
		
		# Animamos los slots de la derecha que estén visibles
		for slot in sub_party_container.get_children():
			if slot.visible:
				actualizar_frame_slot(slot)

func cargar_equipo():
	var equipo = PlayerManager.data.party 
	
	if equipo.is_empty():
		print("No tienes Pokémon en el equipo.")
		return
		
	# 1. Configurar el Pokémon principal (Izquierda)
	configurar_slot(active_panel, equipo[0]) 
	
	# 2. Configurar los demás (Derecha)
	var slots_derecha = sub_party_container.get_children()
	
	for i in range(1, 6):
		if i < equipo.size():
			slots_derecha[i-1].show()
			configurar_slot(slots_derecha[i-1], equipo[i]) 
		else:
			slots_derecha[i-1].hide()

func configurar_slot(nodo_slot, pokemon_data: Pokemon):
	if not pokemon_data: 
		return

	var base_data = pokemon_data.get_base_data()
	if not base_data:
		return

	nodo_slot.get_node("NombreLabel").text = base_data.species_name
	nodo_slot.get_node("NivelLabel").text = "Nv" + str(pokemon_data.level)
	
	# --- AQUÍ CONFIGURAMOS EL ATLAS TEXTURE ---
	var icono_nodo = nodo_slot.get_node("Icono") # Tu TextureButton
	var textura_completa = base_data.icon_sprite
	
	if textura_completa:
		var atlas = AtlasTexture.new()
		atlas.atlas = textura_completa
		
		# Cortamos el frame (Ancho completo, Alto / 2)
		var frame_height = textura_completa.get_height() / 2
		atlas.region = Rect2(0, 0, textura_completa.get_width(), frame_height)
		
		# Asignamos el atlas al botón
		icono_nodo.texture = atlas
		
		# Guardamos el atlas dentro del mismo nodo usando "meta" para poder animarlo en el _process
		nodo_slot.set_meta("icono_atlas", atlas)
	else:
		# Si por alguna razón no hay textura, limpiamos el meta
		if nodo_slot.has_meta("icono_atlas"):
			nodo_slot.remove_meta("icono_atlas")
	# ------------------------------------------
	
	# Configuración de la HPBar
	var hp_bar = nodo_slot.get_node("HPBar")
	var max_hp = pokemon_data.get_max_hp()
	var current_hp = pokemon_data.current_hp

	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

	# --- AQUÍ ACTUALIZAMOS EL TEXTO DE LA VIDA ---
	# Usamos %03d para forzar a Godot a escribir siempre 2 dígitos
	var texto_hp = "%3d/%3d" % [current_hp, max_hp]
	nodo_slot.get_node("HPTextLabel").text = texto_hp
	# ----------------------------------------------

	# Sacamos el porcentaje para pintar la barra
	var porcentaje_vida = (float(current_hp) / float(max_hp)) * 100.0
	
	var estilo_relleno = hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if estilo_relleno:
		estilo_relleno = estilo_relleno.duplicate()
		if porcentaje_vida <= 20.0:
			estilo_relleno.bg_color = Color("#ff4d4d") # Rojo peligro
		elif porcentaje_vida <= 50.0:
			estilo_relleno.bg_color = Color("#ffcc00") # Amarillo mitad
		else:
			estilo_relleno.bg_color = Color("#73ffad") # Verde sano
		hp_bar.add_theme_stylebox_override("fill", estilo_relleno)

# Función auxiliar para mover la región del Atlas en el _process
func actualizar_frame_slot(nodo_slot):
	if nodo_slot.has_meta("icono_atlas"):
		var atlas = nodo_slot.get_meta("icono_atlas") as AtlasTexture
		if atlas and atlas.atlas:
			var frame_height = atlas.atlas.get_height() / 2
			# Desplazamos el origen Y del recorte según el frame actual (0 o 1)
			atlas.region.position.y = current_icon_frame * frame_height

func _input(event):
	if event.is_action_pressed("ui_cancel"): 
		queue_free()
