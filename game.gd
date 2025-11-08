extends Node3D

## Gestiona la lógica principal del juego, incluyendo el menú de pausa.
const SAVE_PATH := "user://savegame.save"
const PAUSE_ACTION := "pause"
const FALLBACK_PAUSE_ACTION := "ui_cancel"

@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var continue_button: Button = $PauseMenu/CenterContainer/Panel/MarginContainer/VBoxContainer/ContinueButton
@onready var status_label: Label = $PauseMenu/CenterContainer/Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var status_timer: Timer = $PauseMenu/StatusTimer
@onready var player: Player = $Player


func _ready() -> void:
    pause_menu.visible = false
    pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    status_label.visible = false
    status_timer.one_shot = true
    status_timer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    _ensure_pause_action_binding()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(PAUSE_ACTION) and not event.is_echo():
        if get_tree().paused:
            _resume_game()
        else:
            _pause_game()


func _pause_game() -> void:
    get_tree().paused = true
    pause_menu.visible = true
    continue_button.grab_focus()


func _resume_game() -> void:
    get_tree().paused = false
    pause_menu.visible = false
    _clear_status_message()


func _on_continue_button_pressed() -> void:
    _resume_game()


func _on_save_button_pressed() -> void:
    var save_data := {
        "scene": get_tree().current_scene.scene_file_path,
        "player": {
            "position": player.global_transform.origin,
            "coins": player.coins
        }
    }

    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_var(save_data, true)
        file.close()
        _show_status_message("Partida guardada.")
    else:
        var error_message := "Error al guardar (" + error_string(FileAccess.get_open_error()) + ")."
        push_warning(error_message)
        _show_status_message("No se pudo guardar.")


func _on_restart_button_pressed() -> void:
    _resume_game()
    get_tree().reload_current_scene()


func _on_status_timer_timeout() -> void:
    _clear_status_message()


func _show_status_message(message: String) -> void:
    status_label.text = message
    status_label.visible = true
    status_timer.start(2.5)


func _clear_status_message() -> void:
    status_label.text = ""
    status_label.visible = false
    if status_timer.is_stopped():
        return
    status_timer.stop()


func _ensure_pause_action_binding() -> void:
    if InputMap.has_action(PAUSE_ACTION):
        return

    InputMap.add_action(PAUSE_ACTION)

    if InputMap.has_action(FALLBACK_PAUSE_ACTION):
        for event in InputMap.action_get_events(FALLBACK_PAUSE_ACTION):
            InputMap.action_add_event(PAUSE_ACTION, event)
        return

    var escape_event := InputEventKey.new()
    escape_event.keycode = Key.ESCAPE
    escape_event.physical_keycode = Key.ESCAPE
    InputMap.action_add_event(PAUSE_ACTION, escape_event)

    var start_event := InputEventJoypadButton.new()
    start_event.button_index = JOY_BUTTON_START
    InputMap.action_add_event(PAUSE_ACTION, start_event)
