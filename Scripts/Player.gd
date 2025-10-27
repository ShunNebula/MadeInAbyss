extends CharacterBody3D

# --- Настройки движения ---
@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002 # Чувствительность мыши

# --- Внутренние переменные ---
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Получаем ссылку на камеру, которую мы добавим на следующем шаге
@onready var camera = $Camera3D

func _ready() -> void:
	# Захватываем курсор мыши, чтобы он не выходил за пределы окна
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# Вращение камеры с помощью мыши
	if event is InputEventMouseMotion:
		# Вращение игрока влево-вправо (вокруг оси Y)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Вращение игрока вверх-вниз (вокруг оси X)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		# Ограничиваем поворот камеры вверх-вниз, чтобы избежать "сальто"
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
func _physics_process(delta: float) -> void:
	# --- Гравитация ---
	# Добавляем гравиттацию, если персонаж не на полу
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- Прыжок ---
	# Обрабатываем прыжок. Input.is_action_just_pressedсрабатывает только один разпри нажатии
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# --- Движение ---
	# Получаем вектор ввода от клавиш (WASD)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Преобразуем 2D-вектор ввода в 3D-направление с учетом поворота игрока
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Применяем движение
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		# Плавное замедление, если клавиши не нажаты
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	# Вызываем встроенную функцию CharacterBody3D, которая обрабатывает движение и столкновения
	move_and_slide()
