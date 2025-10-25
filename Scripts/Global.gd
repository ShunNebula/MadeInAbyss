extends Node

# Инстанс FastNoiseLite, который будет доступен глобально
var noise = FastNoiseLite.new()

func _ready():
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN # Используем шум Перлина
	noise.frequency = 0.02 # Базовая частота (определяет масштаб шума)
	print("Global script loaded and FastNoiseLite initialized.")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
