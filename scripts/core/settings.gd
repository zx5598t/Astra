class_name AstraSettings
extends RefCounted

const DEFAULT_PATH := "user://astra_settings.cfg"

var path: String = DEFAULT_PATH
var master_volume: float = 0.8
var fullscreen: bool = false
var meeting_speed: float = 1.0
var show_hints: bool = true
var ai_enabled: bool = false
var ai_endpoint: String = "http://127.0.0.1:8787/npc/action"

func _init(file_path: String = DEFAULT_PATH) -> void:
    path = file_path

func load_data() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(path) != OK:
        return
    master_volume = clampf(float(cfg.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
    fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
    meeting_speed = clampf(float(cfg.get_value("play", "meeting_speed", meeting_speed)), 0.5, 3.0)
    show_hints = bool(cfg.get_value("play", "show_hints", show_hints))
    ai_enabled = bool(cfg.get_value("ai", "enabled", ai_enabled))
    ai_endpoint = str(cfg.get_value("ai", "endpoint", ai_endpoint))

func save_data() -> bool:
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "master_volume", master_volume)
    cfg.set_value("display", "fullscreen", fullscreen)
    cfg.set_value("play", "meeting_speed", meeting_speed)
    cfg.set_value("play", "show_hints", show_hints)
    cfg.set_value("ai", "enabled", ai_enabled)
    cfg.set_value("ai", "endpoint", ai_endpoint)
    return cfg.save(path) == OK

func apply_audio() -> void:
    var bus := AudioServer.get_bus_index("Master")
    if bus >= 0:
        AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))
        AudioServer.set_bus_mute(bus, master_volume <= 0.001)

func apply_display() -> void:
    if DisplayServer.get_name() == "headless":
        return
    var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
    if DisplayServer.window_get_mode() != mode:
        DisplayServer.window_set_mode(mode)
