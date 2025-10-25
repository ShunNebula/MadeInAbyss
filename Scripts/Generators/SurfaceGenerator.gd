extends Node

@export var size_x: int = 64
@export var size_y: int = 64
@export var noise_scale: float = 0.02 # Масштаб шума, влияет на размер холмов
@export var height_multiplier: float = 5.0 # Максивальная высота холмов

# Узел MeshInstance3D, который будет отображать нашу сгенерированную поверхность
var terrain_mesh_instance: MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("SurfaceGenerator is ready.")
	# Создаём MeshInstance, который будет отображать наш сгенерированный меш
	terrain_mesh_instance = MeshInstance3D.new()
	add_child(terrain_mesh_instance)
	
	# Вызываем йункцию генерации поверхности
	generate_surface()

func generate_surface():
	print("Generating surface...")
	# Здесь будеь логика генерации меша. Пока пусто
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
