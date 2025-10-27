extends Area3D

@export var target_layer_index: int = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Подключаем сигнал 'body_entered' к нашей собственной функции _on_body_entered
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# 'body' - это узел, который вошел в зону.
	# Нам нужно проверить, является ли этот узел игроком.
	# Пока у нас нет игрока, мы можем просто проверить.

	print("Something entered the transition zone: ", body.name)

	# Вызываем функцию в нашем глобальном AbyssManager
	# и передаем ей, на какой слой мы хотим перейти.
	AbyssManager.load_layer(target_layer_index)
