extends Node3D


@export var level_time_seconds := 180.0


var _remaining_time := 0.0
var _time_expired := false
var _objectives: Array[Node3D] = []


@onready var _player: Player = $Player
@onready var _camera: Camera3D = $Player/Target/Camera3D
@onready var _timer_label: Label = %TimerLabel
@onready var _health_bar: TextureProgressBar = %HealthBar
@onready var _power_bar: TextureProgressBar = %PowerBar
@onready var _pause_button: Button = %PauseButton
@onready var _pause_menu: Control = %PauseMenu
@onready var _pause_title: Label = %PauseTitle
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _exit_button: Button = %ExitButton
@onready var _pointer: Control = %ObjectivePointer
@onready var _distance_label: Label = %ObjectiveDistance


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	_remaining_time = level_time_seconds
	_update_timer_label()
	_pause_menu.visible = false
	_pointer.visible = false
	_pause_button.pressed.connect(_on_pause_button_pressed)
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_restart_button.pressed.connect(_on_restart_button_pressed)
	_exit_button.pressed.connect(_on_exit_button_pressed)
	_player.health_changed.connect(_on_player_health_changed)
	_player.power_changed.connect(_on_player_power_changed)
	_player.died.connect(_on_player_died)
	_player.emit_current_stats()
	for node in get_tree().get_nodes_in_group("objective_targets"):
		_register_objective(node)


func _process(delta: float) -> void:
	if not _time_expired and not get_tree().paused:
		_update_timer(delta)
	_update_pointer()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			if _resume_button.visible:
				_resume_game()
		else:
			_pause_game(tr("Pausa"))
		get_viewport().set_input_as_handled()


func _update_timer(delta: float) -> void:
	if _remaining_time <= 0.0:
		return
	_remaining_time = maxf(0.0, _remaining_time - delta)
	_update_timer_label()
	if _remaining_time == 0.0:
		_on_time_expired()


func _update_timer_label() -> void:
	var total_seconds := int(_remaining_time)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	_timer_label.text = "%02d:%02d" % [minutes, seconds]


func _register_objective(target: Node) -> void:
	if target is Node3D and target not in _objectives:
		_objectives.append(target)
		if target.has_signal("collected"):
			target.collected.connect(_on_objective_collected)


func _on_objective_collected(target: Node) -> void:
	_objectives.erase(target)


func _update_pointer() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_camera):
		_pointer.visible = false
		return
	var best_target: Node3D = null
	var best_distance := INF
	for target in _objectives:
		if not is_instance_valid(target):
			continue
		if target.has_method("is_objective_active") and not target.is_objective_active():
			continue
		var distance := _player.global_position.distance_to(target.global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = target
	if best_target == null:
		_pointer.visible = false
		return
	if best_distance < 1.0:
		_pointer.visible = false
		return
	var local_pos := _camera.to_local(best_target.global_position)
	if local_pos.z > -0.1:
		local_pos.z = -0.1
	var angle := atan2(local_pos.x, -local_pos.z)
	_pointer.rotation = angle
	_distance_label.text = "%dm" % int(round(best_distance))
	_pointer.visible = true


func _pause_game(title: String, allow_resume: bool = true) -> void:
	_pause_title.text = title
	_resume_button.visible = allow_resume
	_pause_menu.visible = true
	_pause_button.disabled = true
	get_tree().paused = true


func _resume_game() -> void:
	_pause_menu.visible = false
	_pause_button.disabled = false
	get_tree().paused = false


func _on_pause_button_pressed() -> void:
	_pause_game(tr("Pausa"), true)


func _on_resume_button_pressed() -> void:
	if _resume_button.visible:
		_resume_game()


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://MainMenu.tscn")


func _on_player_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current


func _on_player_power_changed(current: float, maximum: float) -> void:
	_power_bar.max_value = maximum
	_power_bar.value = current


func _on_player_died() -> void:
	_pause_game(tr("Derrota"), false)


func _on_time_expired() -> void:
	_time_expired = true
	_pause_game(tr("Tiempo agotado"), false)
