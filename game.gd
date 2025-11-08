extends Node3D

## Gestiona la lógica principal del juego, incluyendo el menú de pausa.
const SAVE_PATH := "user://savegame.save"
const MAIN_MENU_SCENE := "res://MainMenu.tscn"
const PAUSE_ACTION := "ui_cancel"

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
    _apply_pending_save_data()
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


func _on_exit_button_pressed() -> void:
    _resume_game()
    get_tree().change_scene_to_file(MAIN_MENU_SCENE)


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


func _apply_pending_save_data() -> void:
    if not get_tree().has_meta("load_game_data"):
        return

    var save_data := get_tree().get_meta("load_game_data")
    get_tree().remove_meta("load_game_data")

    if typeof(save_data) != TYPE_DICTIONARY:
        push_warning("[Game] El formato de guardado no es válido.")
        return

    if save_data.has("player"):
        var player_data := save_data["player"]
        if typeof(player_data) == TYPE_DICTIONARY:
            if player_data.has("position"):
                player.global_position = player_data["position"]
                player.initial_position = player.global_position
                player.velocity = Vector3.ZERO
            if player_data.has("coins"):
                player.coins = int(player_data["coins"])
