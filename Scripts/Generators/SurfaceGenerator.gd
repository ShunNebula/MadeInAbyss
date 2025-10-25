extends Node

@export var size_x: int = 10
@export var size_z: int = 10
@export var noise_scale: float = 0.02 # Масштаб шума, влияет на размер холмов
@export var height_multiplier: float = 5.0 # Максивальная высота холмов

@export var octaves: int = 4 # Количество слоёв шума для большей детализации
@export var lacunarity: float = 2.0 # Как быстро меняется частота для следующих октав
@export var persistance: float = 0.5 # Как быстро уменьшается амплитуда для следующих октав

# Узел MeshInstance3D, который будет отображать нашу сгенерированную поверхность
var terrain_mesh_instance: MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("SurfaceGenerator is ready.")
	# Создаём MeshInstance, который будет отображать наш сгенерированный меш
	terrain_mesh_instance = MeshInstance3D.new()
	add_child(terrain_mesh_instance)
	
	# Вызываем функцию генерации поверхности
	generate_surface()

# Функция для получения высоты в точке (x, z)
func _get_height(x: int, z: int) -> float:
	var total_height = 0.0
	var current_ampplitude = 1.0
	var current_frequency = noise_scale # Начинаем с базовой частоты
	
	# Для мульти-октавного шума (фрактальный шум)
	for i in range(octaves):
		# Получаем 2D-шум из нашего гловального FastNoiseLite
		# Умножаем координаты на текущую частоту, чтобы получить разные детали
		# ШУм FastNoiseLite возвращает значения в диапозоне [-1, 1]
		var noise_value = Global.noise.get_noise_2d(float(x) * current_frequency, float(z) * current_frequency)
		
		# Добавляем к общей высоте, умножая на текущую амплитуду
		total_height += noise_value * current_ampplitude
		
		# Обновляем амплитуду и частоту для следующей октавы
		current_ampplitude *= persistance
		current_frequency *= lacunarity
	
	# Нормализуем шум (т.к. tptal_height может выйти за [-1, 1] из-за октав)
	# Этот шаг важен для контроля над height_multiplier.
	var max_amplitude = 0.0 # Максимальная возможная амплитуда для заданного количества октав
	var amp = 1.0
	for i in range(octaves):
		max_amplitude += amp
		amp *= persistance
	
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
	# Временная проверка
	for x in range(size_x):
		for z in range(size_z):
			var h = _get_height(x, z)
			print("Height at (%d, %d): %.2f" % [x, z, h])
	print("Height map generation logic tested.")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
