extends Node

# --- Конфигурация слоёв ---
# Словрь, где ключ - это номер слоя, а значение - путь к его сцене.
const LAYER_SCENES = {
	1: "res://Scenes/Layers/Layer_01_Edge.tscn"
}

# --- Состояние игры ---
var current_layers_index: int = 0
var current_layer_node: Node3D = null

# --- Ссылки на другие узлы ---
# Мы получим ссылку на узел-контейнер в главной сцене.
# @onready - это специальный синтаксис, который гарантирует,
# что get_node будет вызван только когда сцена будет готова.
@onready var layer_container = get_tree().get_root().get_node("Main/LayerContainer")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("AbyssManager is ready.")
	# Загружаем первый слой при старте игры
	load_layer(1)

func load_layer(layer_index: int):
	print("Loading layer %d..." % layer_index)
	
	# Проверяем, существует ли сцена для этого слоя.
	if not LAYER_SCENES.has(layer_index):
		print("ERROR: Layer %d scene not found in LAYER_SCENE." % layer_index)
		return
	
	# 1. Выгружаем предыдущий слой, если он существует.
	if current_layer_node != null:
		current_layer_node.queue_free()
		current_layer_node = null
	
	# 2. Загружаем ресурсы сцены.
	var layer_scene_resource = load(LAYER_SCENES[layer_index])
	if layer_scene_resource == null:
		print("ERROR: Failed to load scene resource for leayer %d." % layer_index)
		return
	
	# 3. Создаём инстанс (экземпляр) сцены.
	current_layer_node = layer_scene_resource.instantiate()
	
	# 4. Добавляем новый слой в сцену (в узел-контейнер).
	layer_container.add_child(current_layer_node)
	
	# 4.5. Запускаем генерацию на добавленном слое
	if current_layer_node.has_method("generate_layer"):
		current_layer_node.generate_layer()
	
	# 5. Обновляем состояние
	current_layers_index = layer_index
	print("Layer %d loaded successfully." % layer_index)
