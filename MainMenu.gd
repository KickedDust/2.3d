extends Control

## Gestiona las interacciones del menú principal.
class_name MainMenu

const GAME_SCENE := "res://game.tscn"
const SAVE_PATH := "user://savegame.save"


func _on_new_game_button_pressed() -> void:
    """Inicia una nueva partida cargando la escena principal del juego."""
    if get_tree().has_meta("load_game_data"):
        get_tree().remove_meta("load_game_data")
    get_tree().change_scene_to_file(GAME_SCENE)


func _on_load_game_button_pressed() -> void:
    """Carga la partida guardada si existe un archivo válido."""
    if not FileAccess.file_exists(SAVE_PATH):
        push_warning("[MainMenu] No hay una partida guardada para cargar.")
        return

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_warning("[MainMenu] No se pudo abrir el archivo de guardado: " + error_string(FileAccess.get_open_error()))
        return

    var save_data := file.get_var(true)
    file.close()

    if typeof(save_data) != TYPE_DICTIONARY:
        push_warning("[MainMenu] El archivo de guardado está corrupto.")
        return

    get_tree().set_meta("load_game_data", save_data)

    var scene_path := GAME_SCENE
    if save_data.has("scene") and typeof(save_data["scene"]) == TYPE_STRING:
        var requested_scene := String(save_data["scene"])
        if ResourceLoader.exists(requested_scene):
            scene_path = requested_scene

    get_tree().change_scene_to_file(scene_path)


func _on_options_button_pressed() -> void:
    """Punto de entrada para mostrar un menú de opciones."""
    print("[MainMenu] Opciones aún no está implementado.")


func _on_exit_button_pressed() -> void:
    """Cierra el juego."""
    get_tree().quit()
