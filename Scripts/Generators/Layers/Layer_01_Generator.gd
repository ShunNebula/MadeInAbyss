extends Node3D

@export var size_x: int = 64
@export var size_z: int = 64
@export var noise_scale: float = 0.02      # Масштаб шума, влияет на размер холмов
@export var height_multiplier: float = 5.0 # Максивальная высота холмов

@export var octaves: int = 4               # Количество слоёв шума для большей детализации
@export var lacunarity: float = 2.0        # Как быстро меняется частота для следующих октав
@export var persistence: float = 0.5       # Как быстро уменьшается амплитуда для следующих октав

@export var surface_material: Material

@export var hole_radius: float = 8.0

# Узел MeshInstance3D, который будет отображать нашу сгенерированную поверхность
var terrain_mesh_instance: MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Layer 01 Generator is ready.")
	#generate_surface()

func generate_layer():
	terrain_mesh_instance = MeshInstance3D.new()
	add_child(terrain_mesh_instance)
	generate_surface()

# Функция для получения высоты в точке (x, z)
func _get_height(x: int, z: int) -> float:
	var total_height = 0.0
	var current_amplitude = 1.0
	var current_frequency = noise_scale # Начинаем с базовой частоты
	
	# Для мульти-октавного шума (фрактальный шум)
	for i in range(octaves):
		# Получаем 2D-шум из нашего гловального FastNoiseLite
		# Умножаем координаты на текущую частоту, чтобы получить разные детали
		# ШУм FastNoiseLite возвращает значения в диапозоне [-1, 1]
		var noise_value = Global.noise.get_noise_2d(float(x) * current_frequency, float(z) * current_frequency)
		
		# Добавляем к общей высоте, умножая на текущую амплитуду
		total_height += noise_value * current_amplitude
		
		# Обновляем амплитуду и частоту для следующей октавы
		current_amplitude *= persistence
		current_frequency *= lacunarity
	
	# Нормализуем шум (т.к. tptal_height может выйти за [-1, 1] из-за октав)
	# Этот шаг важен для контроля над height_multiplier.
	var max_amplitude = 0.0 # Максимальная возможная амплитуда для заданного количества октав
	var amp = 1.0
	for i in range(octaves):
		max_amplitude += amp
		amp *= persistence
	
	# Если max_amplitude > 0, нормализуем, иначе избегаем деления на ноль.
	if max_amplitude > 0:
		total_height /= max_amplitude
	else:
		total_height = 0.0
	
	# Преобразуем шум [-1, 1] в [0, 1] (для удобства работы с высотами)
	# Затем умножаем на height_multiplier, чтобы получить итоговую высоту
	return (total_height + 1.0) * 0.5 * height_multiplier

func generate_surface():
	print("Generating surface...")

	# Инициализируем массивы, которые будут хранить данные нашего меша
	var vertices: PackedVector3Array = PackedVector3Array()  # Позиции вершин (X, Y, Z)
	var normals: PackedVector3Array = PackedVector3Array()   # Нормали вершин (для освещения)
	var uvs: PackedVector2Array = PackedVector2Array()       # UV-координаты (для текстур)
	var indices: PackedInt32Array = PackedInt32Array()       # Индексы, определяющие треугольники
	
	var offset_x = float(size_x) / 2.0
	var offset_z = float(size_z) / 2.0
	
	# Проходим по нашей сетке, чтобы создать вершины
	# x_idx и z_idx - это индексы в нашей сетке
	for x_idx in range(size_x + 1): # +1, потому что у сетки N квадратов, но N+1 вершин
		for z_idx in range(size_z + 1): # То же самое по Z

			# Пока создаем плоскую сетку, Y=0. Позже здесь будет _get_height().
			var height = _get_height(x_idx, z_idx)

			# Создаем новую вершину (позицию в 3D пространстве)
			var vertex_position = Vector3(float(x_idx) - offset_x, height, float(z_idx) - offset_z)
			vertices.append(vertex_position)

			# Пока что для нормалей и UV просто добавляем заглушки.
			# Мы их рассчитаем корректно в следующих шагах.
			normals.append(Vector3.ZERO) # Временно направляем нормали вверх
			uvs.append(Vector2(float(x_idx) / size_x, float(z_idx) / size_z))
	
	# Теперь, когда у нас есть все вершины, нам нужно создать треугольники из них
	# Каждый квадрат в сетке состоит из двух треугольников
	# Используем size_x и size_z (без +1), т.к. это количество квадратов
	for x_idx in range(size_x):
		for z_idx in range(size_z):
			var square_center_x = float(x_idx) - offset_x + 0.5
			var square_center_z = float(z_idx) - offset_z + 0.5
			
			var distance_center = sqrt(square_center_x * square_center_x + square_center_z * square_center_z)
			
			if distance_center < hole_radius:
				continue
			
			# Индексы вершин для текущего квадрата:
			# v0---v1
			# |     |
			# v2---v3

			# Индекс вершины в массиве vertices для (x_idx, z_idx)
			# (size_z + 1) - это количество вершин в одном ряду по Z
			var v0 = x_idx * (size_z + 1) + z_idx
			var v1 = (x_idx + 1) * (size_z + 1) + z_idx
			var v2 = x_idx * (size_z + 1) + (z_idx + 1)
			
			# Первый треугольник (v0, v2, v1)
			indices.append(v0)
			indices.append(v1)
			indices.append(v2)
			
			var p0 = vertices[v0]
			var p1 = vertices[v1]
			var p2 = vertices[v2]
			
			var normal1 = (p1 - p0).cross(p2 - p0).normalized()
			normals[v0] += normal1
			normals[v1] += normal1
			normals[v2] += normal1
			
			var v3 = (x_idx + 1) * (size_z + 1) + (z_idx + 1)
			
			# Второй треугольник (v1, v2, v3)
			indices.append(v1)
			indices.append(v3)
			indices.append(v2)
			
			var p3 = vertices[v3]
			var normal2 = (p3 - p1).cross(p2 - p1).normalized()
			normals[v1] += normal2
			normals[v3] += normal2
			normals[v2] += normal2
	
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()

	# Создаем ArrayMesh и добавляем в него данные
	var array_mesh = ArrayMesh.new()

	# Создаем массив всех необходимых массивов для ArrayMesh
	# Порядок важен! Используем константы Mesh.ARRAY_MAX
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX] = indices

	# Добавляем поверхность к ArrayMesh
	# Mesh.PRIMITIVE_TRIANGLES говорит Godot, что это список треугольников
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

	# Присваиваем сгенерированный меш нашему MeshInstance3D
	terrain_mesh_instance.mesh = array_mesh
	terrain_mesh_instance.material_override = surface_material # Применяем наш материал
	terrain_mesh_instance.create_trimesh_collision()

	print("Surface generated with %d vertices and %d triangles." % [vertices.size(), indices.size() / 3.0])
