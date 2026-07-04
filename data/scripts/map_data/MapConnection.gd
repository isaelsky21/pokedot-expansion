extends Resource

class_name MapConnection

@export_file("*.tscn") var map_scene_path: String
## Desfase en cantidad de baldosas (tiles) tanto en el eje X como en el eje Y.
## Permite alinear con total libertad los mapas vecinos en el inspector.
@export var offset: Vector2i = Vector2i.ZERO
