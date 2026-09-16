class_name AstraIncidentStage
extends PanelContainer

func configure(state) -> void:
    custom_minimum_size = Vector2(0, 225)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.03, 0.06, 0.11, 0.92)
    style.border_color = _case_color(str(state.case_id))
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    add_theme_stylebox_override("panel", style)

    var root := HBoxContainer.new()
    root.add_theme_constant_override("separation", 16)
    add_child(root)

    var visual := TextureRect.new()
    visual.custom_minimum_size = Vector2(300, 195)
    visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    var path: String = str(state.environment_asset_path())
    if ResourceLoader.exists(path):
        visual.texture = load(path)
    root.add_child(visual)

    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation", 7)
    root.add_child(info)
    info.add_child(_label("SCENE // %s" % str(state.case_subtitle).to_upper(), 15, _case_color(str(state.case_id))))
    info.add_child(_label(str(state.case_title), 28, Color("eef5ff")))
    info.add_child(_label("VICTIM · %s" % str(state.truth.incident.get("victim", "Unknown")), 17, Color("ff9aa8")))
    info.add_child(_label(_scene_status(str(state.case_id)), 15, Color("a8bad5")))
    var objective := _label(str(state.truth.incident.get("objective", "")), 15, Color("d9e6f7"))
    objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_child(objective)
    var location_names := PackedStringArray()
    for location in state.truth.incident.get("locations", []):
        location_names.append(str(location))
    info.add_child(_label("LOCATIONS · %s" % "  /  ".join(location_names), 13, Color("7f96b5")))

func _scene_status(case_id: String) -> String:
    match case_id:
        "GLASS_GARDEN": return "BIOHAZARD QUARANTINE · 영양액/정수 계통 동시 교란"
        "ECHO_WARD": return "CRYO LOCKDOWN · 의료기록 복제와 포드 해제 시간차"
        _: return "COMMAND LOCKDOWN · 통신 두절과 전력 우회 동시 발생"

func _case_color(case_id: String) -> Color:
    match case_id:
        "GLASS_GARDEN": return Color("71e39b")
        "ECHO_WARD": return Color("a78cff")
        _: return Color("55d6ff")

func _label(text: String, size_px: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", size_px)
    label.add_theme_color_override("font_color", color)
    return label
