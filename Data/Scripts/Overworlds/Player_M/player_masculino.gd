extends CharacterBody2D

## Clase controladora del personaje jugable (Movimiento por cuadrículas estilo RPG clásico).
## Administra los inputs de dirección, estados de caminata, colisiones lógicas,
## menús de interfaz y animaciones interpoladas por baldosas.

var start_menu: Node = null # Almacena la instancia activa del menú de pausa

signal paso_terminado # Se emite al finalizar por completo el desplazamiento de una baldosa
var puede_encadenar_paso := true # Bandera que determina si el jugador puede ligar un paso con el siguiente

@export_group("Configuración de Movimiento")
@export var duracion_paso: float = 0.30 # Tiempo (en segundos) que tarda en recorrer una baldosa
@export var tile_block: int = 16 # Tamaño de la cuadrícula en píxeles
@export var velocidad_animacion: float = 0.75 # Factor de velocidad aplicado al AnimationPlayer
@export var tiempo_para_caminar: float = 0.12 # Retraso mínimo de pulsación para pasar de "mirar" a "caminar"
@export var map_manager: MapManager # Enlace al administrador de mapas para verificar físicas

# Variables de Control de Estado Interno
var moviendose := false # Verdadero si el personaje está ejecutando un desplazamiento
var posicion_inicio: Vector2 # Posición de origen antes de dar un paso
var posicion_obj: Vector2 # Posición de destino (Baldosa a la que se dirige)
var tiempo_paso := 0.0 # Cronómetro interno para la interpolación matemática (Lerp)
var direccion := Vector2.DOWN # Dirección actual hacia donde se orienta el personaje
# Manejo de Buffers de Entrada
var direccion_input := Vector2.ZERO # Último input capturado del teclado/mando
var tiempo_input := 0.0 # Tiempo acumulado con una tecla de dirección presionada

@onready var anim_player: AnimationPlayer = $AnimationPlayer # Referencia al reproductor de animaciones
@onready var sfx_bump: AudioStreamPlayer = $SfxBump # Referencia de Sonido
@onready var sfx_jump: AudioStreamPlayer = $SfxJump

# Diccionario para mapear vectores bidimensionales a sufijos de cadenas de animación
var dir_to_anim: Dictionary = {
	Vector2.UP: "up",
	Vector2.DOWN: "down",
	Vector2.LEFT: "left",
	Vector2.RIGHT: "right",
}
#funciòn de inicio donde se define la posicion del objetivo y se iguala a la posicion para luego llamar a la funcion de mostrar idle con la variable direccion.
func _ready():
	# Inicializa los objetivos y fuerza la pose de descanso en la dirección por defecto
	posicion_obj = position
	mostrar_idle(direccion)

#funcion para manejar startmenu
func _process(_delta):
	# Captura la entrada global del menú (Tecla de confirmación / Start)
	if Input.is_action_just_pressed("ui_accept"):
		if start_menu == null:
			abrir_menu()
		else:
			cerrar_menu()
## Instancia de manera dinámica el menú de pausa en la raíz de la escena.
func abrir_menu():
	var menu_scene = preload("res://Esenas/Menus/StartMenu/startmenu.tscn")
	start_menu = menu_scene.instantiate()
	get_tree().current_scene.add_child(start_menu)
	start_menu.toggle_menu()  # <-- aquí lo activas

## Libera la memoria del menú de pausa y limpia su referencia del script.
func cerrar_menu():
	if start_menu != null:
		start_menu.queue_free()
		start_menu = null


#funcion donde se maneja la fisica en la cual se verifica si el jugador se esta moviendo, si es asi, se llama la funcion actualizar movimiento, de lo contrario llamamos la funcion que maneja la input estando quieto.
func _physics_process(delta):
	# Si el menú de pausa está interactuando, congela las físicas del personaje
	if start_menu != null and start_menu.is_open:
		mostrar_idle(direccion) # opcional
		return
	# Máquina de estados física rudimentaria dividida en movimiento y quietud
	if moviendose:
		actualizar_movimiento(delta)
	else:
		manejar_input_quieto(delta)

## Procesa la interpolación lineal (Lerp) de la posición del jugador frame a frame.
## Controla el fin del ciclo de un paso y analiza inputs encadenados.
## Procesa la interpolación lineal (Lerp) de la posición del jugador frame a frame.
func actualizar_movimiento(delta: float):
	tiempo_paso += delta
	var t: float = tiempo_paso / duracion_paso
	t = clamp(t, 0.0, 1.0)
	
	position = posicion_inicio.lerp(posicion_obj, t)
	
	if t < 1.0:
		return
		
	position = posicion_obj
	moviendose = false
	puede_encadenar_paso = true
	
	# Al emitir esto, el MapManager actualizará las costuras con la posición final perfecta
	paso_terminado.emit()
	
	if not puede_encadenar_paso:
		mostrar_idle(direccion)
		return
		
	var dir := obtener_direccion_input()
	if dir != Vector2.ZERO:
		empezar_paso(dir)
	else:
		mostrar_idle(direccion)
## Controla el comportamiento del personaje cuando está estático en una baldosa.
func manejar_input_quieto(delta: float):
	var dir := obtener_direccion_input()
	# Si no hay entrada de dirección, limpia buffers y mantiene estado Idle
	if dir == Vector2.ZERO:
		direccion_input = Vector2.ZERO
		tiempo_input = 0.0
		mostrar_idle(direccion)
		return
	# Si el input es diferente a donde mira el personaje, ejecuta un giro rápido sin desplazarse
	if dir != direccion:
		mirar_hacia(dir)
		direccion_input = dir
		tiempo_input = 0.0
		return
	# Si cambia de dirección de input de golpe, resetea el temporizador de buffer
	if dir != direccion_input:
		direccion_input = dir
		tiempo_input = 0.0
		
	# Acumula el tiempo que se mantiene presionada la misma tecla
	tiempo_input += delta
	
	# Si supera el umbral de retención, intenta romper la quietud e iniciar la caminata
	if tiempo_input >= tiempo_para_caminar:
		if map_manager != null and not map_manager.puede_caminar(position, dir):
			# Interceptamos con tu función original para que no suene el bump en la rampa
			if map_manager.has_method("es_rampa") and map_manager.es_rampa(position, dir):
				empezar_paso(dir)
				return
				
			# Sonido continuo rítmico al quedarse corriendo contra paredes
			if sfx_bump and not sfx_bump.playing:
				sfx_bump.play()
			tiempo_input = 0.0 
		else:
			empezar_paso(dir)
## Inicializa los vectores lógicos de destino para el movimiento lineal o diagonal.
func empezar_paso(dir: Vector2):
	# 1. Interceptamos si el destino es una escalera lateral ANTES de evaluar colisiones normales
	if map_manager != null and map_manager.has_method("obtener_tipo_escalera"):
		var tipo = map_manager.obtener_tipo_escalera(position, dir)
		if tipo == "escalera_sube_derecha" or tipo == "escalera_sube_izquierda":
			ejecutar_paso_escalera(dir, tipo)
			return

	# 2. Interceptamos si el destino es una rampa (Usando tu función original del MapManager)
	if map_manager != null and map_manager.has_method("es_rampa"):
		if map_manager.es_rampa(position, dir):
			ejecutar_salto_rampa(dir)
			return
	# NOTA: Si luego implementas el salto direccional que hablamos, cambias "es_rampa" por "validar_salto_rampa"

	# 3. Validador de colisión estándar para muros ordinarios
	if map_manager != null and not map_manager.puede_caminar(position, dir):
		# ¡BUMP! Chocamos de golpe en el primer frame
		if sfx_bump and not sfx_bump.playing:
			sfx_bump.play()
		mostrar_idle(direccion)
		return
	
	# 4. Flujo normal para suelo plano ordinario libre
	direccion = dir
	direccion_input = dir
	tiempo_input = 0.0

	posicion_inicio = position
	posicion_obj = position + dir * tile_block 
	tiempo_paso = 0.0
	moviendose = true

	reproducir_caminata(dir)

## Ejecuta la rutina especial de salto de repisas.
## Modifica la lógica física para avanzar 2 baldosas de golpe mientras altera
## la posición local del Sprite2D de forma parabólica para simular altura.
## Ejecuta la rutina especial de salto de repisas.
func ejecutar_salto_rampa(dir: Vector2):
	moviendose = true
	direccion = dir
	tiempo_input = 0.0
	posicion_inicio = position
	
	# Saltamos 2 casillas de golpe
	posicion_obj = position + dir * (tile_block * 2) 
	tiempo_paso = 0.0
	
	# 🔥 ¡REPRODUCIR SONIDO DE SALTO AQUÍ!
	if sfx_jump and not sfx_jump.playing:
		sfx_jump.play()
	
	var duracion_original = duracion_paso
	duracion_paso = 0.40 
	
	reproducir_caminata(dir)
	
	# --- ANIMACIÓN DE ARCO VISUAL (PARÁBOLA) ---
	var sprite = $Sprite2D 
	if sprite:
		var tween_arco = create_tween() 
		tween_arco.tween_property(sprite, "position:y", -14, duracion_paso / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_arco.tween_property(sprite, "position:y", 0, duracion_paso / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
	await self.paso_terminado
	duracion_paso = duracion_original
## Actualiza la orientación visual del personaje sin alterar su posición por cuadrículas.
func mirar_hacia(dir: Vector2):
	direccion = dir
	mostrar_idle(dir)
## Determina y reproduce el set de animaciones de desplazamiento cíclico.
func reproducir_caminata(dir: Vector2):
	var anim_name := obtener_animacion("walk", dir)

	if anim_player.current_animation == anim_name and anim_player.is_playing():
		return

	anim_player.speed_scale = velocidad_animacion
	anim_player.play(anim_name)
## Pausa la animación en el primer frame de su ciclo para simular una postura estática.
func mostrar_idle(dir: Vector2):
	var anim_name := obtener_animacion("walk", dir)

	if anim_player.current_animation != anim_name:
		anim_player.speed_scale = 1.0
		anim_player.play(anim_name)

	anim_player.seek(0.0, true) # Salta al frame inicial
	anim_player.pause() # Congela la reproducción
## Concatena el tipo de acción y la dirección para construir el nombre del nodo de animación exacto.
func obtener_animacion(tipo: String, dir: Vector2) -> String:
	return tipo + "_" + String(dir_to_anim[dir])
## Escucha los mapeos de entrada del proyecto para retornar vectores unitarios limpios.
func obtener_direccion_input() -> Vector2:
	if Input.is_action_pressed("Up"):
		return Vector2.UP
	elif Input.is_action_pressed("Down"):
		return Vector2.DOWN
	elif Input.is_action_pressed("Left"):
		return Vector2.LEFT
	elif Input.is_action_pressed("Right"):
		return Vector2.RIGHT

	return Vector2.ZERO
## Desactiva el flag de encadenamiento para interrumpir movimientos continuos automatizados.
func cancelar_encadenado():
	puede_encadenar_paso = false

## Ejecuta la rutina especial de caminata en escaleras laterales.
## Mueve al jugador horizontalmente en la cuadrícula mientras altera la Y local
## del Sprite2D con un Tween para simular el ascenso o descenso diagonal.
## Ejecuta la rutina especial de caminata en escaleras laterales.
## Mueve al jugador de forma diagonal real por la cuadrícula (X e Y cambian juntos).
## Desactiva temporalmente las capas físicas para evitar que los muros colindantes traben el eje Y.
func ejecutar_paso_escalera(dir: Vector2, tipo_escalera: String):
	moviendose = true
	direccion = dir
	tiempo_input = 0.0
	posicion_inicio = position
	
	# 1. Determinamos el vector diagonal real (X e Y cambian a la vez)
	var dir_diagonal = dir
	if tipo_escalera == "escalera_sube_derecha":
		if dir == Vector2.RIGHT: dir_diagonal = Vector2(1, -1)  # Sube derecha
		if dir == Vector2.LEFT:  dir_diagonal = Vector2(-1, 1)  # Baja izquierda
	elif tipo_escalera == "escalera_sube_izquierda":
		if dir == Vector2.LEFT:  dir_diagonal = Vector2(-1, -1) # Sube izquierda
		if dir == Vector2.RIGHT: dir_diagonal = Vector2(1, 1)   # Baja derecha
	
	# El cuerpo calcula su destino diagonal real en píxeles
	posicion_obj = position + dir_diagonal * tile_block
	tiempo_paso = 0.0
	
	# 2. Desactivamos colisiones físicas antes de movernos para que los muros no frenen la Y
	var capa_original = collision_layer
	var mascara_original = collision_mask
	collision_layer = 0
	collision_mask = 0
	
	reproducir_caminata(dir)
	
	# 3. Esperamos a que el proceso nativo de actualizar_movimiento (el Lerp) complete el viaje
	await self.paso_terminado
	
	# 4. Al llegar a la meta, restauramos las capas físicas originales de inmediato
	collision_layer = capa_original
	collision_mask = mascara_original
