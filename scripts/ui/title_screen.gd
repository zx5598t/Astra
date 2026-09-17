class_name AstraTitleScreen
extends Control

# Incident archive: continue button, three case files with unlock state and
# best rank, investigator protocol selection, help / settings / quit.

var app
var _protocol_row: HBoxContainer
var _continue: Button

func setup(app_node) -> void:
    app = app_node
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var root := AstraUI.vbox(16)
    var margin := AstraUI.margin(root, 44, 30, 44, 26)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)
    var meta: AstraMetaProgress = app.meta

    var header := AstraUI.hbox(18)
    root.add_child(header)
    var brand := AstraUI.vbox(2)
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(brand)
    brand.add_child(AstraUI.label("OBSERVER PROGRAM · INCIDENT ARCHIVE", 14, AstraUI.CYAN))
    brand.add_child(AstraUI.label("ASTRA", 64, AstraUI.TEXT))
    brand.add_child(AstraUI.label("여덟 명의 승무원, 두 명의 Null. 기록은 거짓말을 하지 않지만, 사람은 한다.", 17, AstraUI.MUTED))
    var record := AstraUI.vbox(2)
    record.alignment = BoxContainer.ALIGNMENT_CENTER
    header.add_child(record)
    record.add_child(_right_label(meta.archive_rank(), 22, AstraUI.GOLD))
    record.add_child(_right_label("%s · 조사 %d회 · Null 격리 %d명" % [meta.campaign_summary(), meta.total_cases_completed, meta.correct_isolations], 14, AstraUI.TEXT))
    record.add_child(_right_label("통찰 %d · 최고 추리 %d점" % [meta.total_insight, meta.best_theory_score], 13, AstraUI.MUTED))

    root.add_child(AstraUI.section("사건 파일"))
    var cases := AstraUI.hbox(14)
    cases.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(cases)
    for case_id in AstraCaseCatalog.CAMPAIGN:
        cases.add_child(_case_card(str(case_id)))

    root.add_child(AstraUI.section("조사 방식 · 매 사건 시작 전에 고릅니다"))
    _protocol_row = AstraUI.hbox(12)
    root.add_child(_protocol_row)
    _refresh_protocols()

    var footer := AstraUI.hbox(10)
    root.add_child(footer)
    var recommended := meta.recommended_case_id()
    _continue = AstraUI.button("▶  %s  %s" % ["조사 시작" if meta.total_cases_completed == 0 else "이어서 조사", meta.case_display_name(recommended)], AstraUI.CYAN, 20, 60, true)
    _continue.custom_minimum_size = Vector2(520, 60)
    _continue.pressed.connect(func(): app.start_case(recommended, app.selected_protocol))
    footer.add_child(_continue)
    footer.add_child(AstraUI.spacer())
    var help := AstraUI.button("플레이 방법", AstraUI.MUTED, 16, 52)
    help.custom_minimum_size = Vector2(140, 52)
    help.pressed.connect(func(): app.show_help())
    footer.add_child(help)
    var settings := AstraUI.button("설정", AstraUI.MUTED, 16, 52)
    settings.custom_minimum_size = Vector2(100, 52)
    settings.pressed.connect(func(): app.show_settings())
    footer.add_child(settings)
    var quit := AstraUI.button("종료", AstraUI.MUTED, 16, 52)
    quit.custom_minimum_size = Vector2(100, 52)
    quit.pressed.connect(func(): app.quit_game())
    footer.add_child(quit)
    var version := AstraUI.label("v" + app.version_text(), 12, AstraUI.DIM)
    version.size_flags_vertical = Control.SIZE_SHRINK_END
    footer.add_child(version)

func _right_label(text: String, size: int, color: Color) -> Label:
    var node := AstraUI.label(text, size, color)
    node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    return node

func _case_card(case_id: String) -> Control:
    var meta: AstraMetaProgress = app.meta
    var data := AstraCaseCatalog.get_case(case_id)
    var accent := Color(str(data.get("accent", "55d6ff")))
    var unlocked := meta.is_case_unlocked(case_id)
    var card := AstraUI.panel(AstraUI.PANEL, Color(accent, 0.55 if unlocked else 0.2), 14, 0)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.clip_contents = true
    var box := AstraUI.vbox(0)
    card.add_child(box)
    var art_frame := Control.new()
    art_frame.custom_minimum_size = Vector2(0, 150)
    art_frame.clip_contents = true
    box.add_child(art_frame)
    var art := AstraUI.thumb(str(data.get("environment", "")), Vector2(0, 150))
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    art.modulate = Color(1, 1, 1, 0.9) if unlocked else Color(0.4, 0.42, 0.5, 0.7)
    art_frame.add_child(art)
    var code := AstraUI.chip(str(data.get("code", "")), accent, 12)
    code.position = Vector2(14, 12)
    art_frame.add_child(code)
    var info := AstraUI.vbox(6)
    info.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(AstraUI.margin(info, 18, 14, 18, 18))
    info.add_child(AstraUI.label(str(data.get("title", "")), 28, AstraUI.TEXT if unlocked else AstraUI.DIM))
    info.add_child(AstraUI.label("%s · %s" % [str(data.get("title_ko", "")), str(data.get("theme", ""))], 14, AstraUI.MUTED))
    info.add_child(AstraUI.label(str(data.get("card_line", "")), 15, AstraUI.TEXT if unlocked else AstraUI.DIM, true))
    var stars := ""
    for index in range(3):
        stars += "●" if index < int(data.get("difficulty", 1)) else "○"
    var tags := AstraUI.hbox(6)
    info.add_child(tags)
    tags.add_child(AstraUI.chip("난이도 " + stars, AstraUI.GOLD, 12))
    var rank := meta.best_case_rank(case_id)
    if rank != "":
        tags.add_child(AstraUI.chip("최고 " + rank, AstraUI.GREEN, 12))
    info.add_child(AstraUI.spacer(false))
    info.add_child(AstraUI.label(meta.case_status(case_id), 13, AstraUI.GREEN if meta.case_status(case_id).begins_with("해결") else (AstraUI.GOLD if unlocked else AstraUI.DIM)))
    if unlocked:
        var start := AstraUI.button("조사 시작", accent, 17, 48, true)
        start.pressed.connect(func(): app.start_case(case_id, app.selected_protocol))
        info.add_child(start)
    else:
        info.add_child(AstraUI.label(meta.unlock_hint(case_id), 13, AstraUI.DIM, true))
        var locked := AstraUI.button("잠김", AstraUI.DIM, 17, 48)
        locked.disabled = true
        info.add_child(locked)
    return card

func _refresh_protocols() -> void:
    AstraUI.clear(_protocol_row)
    for protocol_id in ["ANALYST", "EMPATH", "AUDITOR"]:
        var spec: Dictionary = AstraGameSession.PROTOCOLS[protocol_id]
        var selected: bool = app.selected_protocol == protocol_id
        var accent := AstraUI.GOLD if protocol_id == "ANALYST" else (AstraUI.GREEN if protocol_id == "EMPATH" else AstraUI.VIOLET)
        var card := AstraUI.panel(Color(accent, 0.14) if selected else AstraUI.PANEL, accent if selected else AstraUI.BORDER, 12, 12)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.mouse_filter = Control.MOUSE_FILTER_STOP
        card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        card.gui_input.connect(_on_protocol_input.bind(protocol_id))
        var box := AstraUI.vbox(3)
        box.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_child(box)
        var head := AstraUI.hbox(8)
        head.mouse_filter = Control.MOUSE_FILTER_IGNORE
        box.add_child(head)
        head.add_child(AstraUI.label(("● " if selected else "○ ") + str(spec.get("name", "")), 18, accent if selected else AstraUI.TEXT))
        head.add_child(AstraUI.label(protocol_id, 11, AstraUI.DIM))
        box.add_child(AstraUI.label(str(spec.get("summary", "")), 14, AstraUI.TEXT, true))
        box.add_child(AstraUI.label(str(spec.get("detail", "")), 12, AstraUI.MUTED, true))
        _protocol_row.add_child(card)

func _on_protocol_input(event: InputEvent, protocol_id: String) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        app.selected_protocol = protocol_id
        app.fx.play("select")
        _refresh_protocols()
