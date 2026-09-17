class_name AstraTitleScreen
extends Control

# One focused dossier at a time: route selection, a character-led hero, then
# a single clear start action. Locked chapters remain readable previews.
var app
var _selected_case: String = ""
var _case_list: VBoxContainer
var _detail: VBoxContainer
var _protocol_row: HBoxContainer
var _continue: Button

func setup(app_node) -> void:
    app = app_node
    _selected_case = app.meta.recommended_case_id()
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var root := AstraUI.vbox(18)
    var margin := AstraUI.margin(root, 36, 24, 36, 24)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)
    var header := AstraUI.hbox(20)
    root.add_child(header)
    header.add_child(AstraUI.label("A S T R A", 42, AstraUI.TEXT))
    var tagline := AstraUI.vbox(3)
    tagline.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    header.add_child(tagline)
    tagline.add_child(AstraUI.label("THE LAST LIGHT  /  마지막 빛", 13, AstraUI.CYAN))
    tagline.add_child(AstraUI.label("우주선 위의 여덟 사람. 믿음과 거짓 사이의 당신.", 14, AstraUI.MUTED))
    header.add_child(AstraUI.spacer())
    var progress := AstraUI.vbox(4)
    progress.alignment = BoxContainer.ALIGNMENT_CENTER
    header.add_child(progress)
    progress.add_child(AstraUI.label(app.meta.archive_rank(), 17, AstraUI.GOLD))
    progress.add_child(AstraUI.label(app.meta.campaign_summary() + "  ·  통찰 %d" % app.meta.total_insight, 13, AstraUI.MUTED))

    var body := AstraUI.hbox(24)
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(body)
    var nav := AstraUI.vbox(10)
    nav.custom_minimum_size = Vector2(276, 0)
    body.add_child(nav)
    nav.add_child(AstraUI.section("항해 기록  /  CAMPAIGN"))
    nav.add_child(AstraUI.label("사건을 선택하고, 진실에 한 걸음 더.", 13, AstraUI.MUTED))
    _case_list = AstraUI.vbox(7)
    nav.add_child(AstraUI.scroll(_case_list))
    nav.add_child(AstraUI.label("1인용 추리 RPG  ·  오프라인 플레이\n매번 달라지는 범인 · 증거 · 알리바이", 12, AstraUI.DIM))
    _detail = AstraUI.vbox(12)
    _detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_child(_detail)

    root.add_child(AstraUI.section("나의 조사 방식  /  선택한 능력은 이 사건 동안 유지됩니다"))
    _protocol_row = AstraUI.hbox(12)
    root.add_child(_protocol_row)
    _refresh_protocols()
    var footer := AstraUI.hbox(10)
    root.add_child(footer)
    _continue = AstraUI.button("", AstraUI.CYAN, 19, 56, true)
    _continue.custom_minimum_size = Vector2(410, 56)
    _continue.pressed.connect(_start_selected)
    footer.add_child(_continue)
    var saved := AstraGameSession.snapshot_info(app.snapshot_path())
    if not saved.is_empty():
        var resume := AstraUI.button("계속하기 · DAY %d" % int(saved.get("day", 1)), AstraUI.GREEN, 16, 56, true)
        resume.pressed.connect(func(): app.resume_case())
        footer.add_child(resume)
    footer.add_child(AstraUI.spacer())
    var crew := AstraUI.button("승무원 기록", AstraUI.MUTED, 14, 46)
    crew.pressed.connect(_crew_archive)
    footer.add_child(crew)
    var help := AstraUI.button("플레이 방법", AstraUI.MUTED, 14, 46)
    help.pressed.connect(func(): app.show_help())
    footer.add_child(help)
    var settings := AstraUI.button("설정", AstraUI.MUTED, 14, 46)
    settings.pressed.connect(func(): app.show_settings())
    footer.add_child(settings)
    var quit := AstraUI.button("종료", AstraUI.MUTED, 14, 46)
    quit.pressed.connect(func(): app.quit_game())
    footer.add_child(quit)
    footer.add_child(AstraUI.label("v" + app.version_text(), 12, AstraUI.DIM))
    _refresh_cases()
    _refresh_detail()

func _refresh_cases() -> void:
    AstraUI.clear(_case_list)
    var number := 0
    for case_id in AstraCaseCatalog.CAMPAIGN:
        number += 1
        var data := AstraCaseCatalog.get_case(str(case_id))
        var unlocked: bool = app.meta.is_case_unlocked(str(case_id))
        var selected := _selected_case == str(case_id)
        var color := AstraUI.CYAN if selected else AstraUI.MUTED
        var button := AstraUI.button("%02d   %s\n        %s" % [number, str(data.get("title", "")), str(data.get("title_ko", "")) + ("  ·  잠김" if not unlocked else "")], color, 16, 69, selected)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.tooltip_text = app.meta.case_status(str(case_id)) if unlocked else app.meta.unlock_hint(str(case_id))
        button.pressed.connect(_select_case.bind(str(case_id)))
        _case_list.add_child(button)

func _select_case(case_id: String) -> void:
    _selected_case = case_id
    app.fx.play("select")
    _refresh_cases()
    _refresh_detail()

func _refresh_detail() -> void:
    AstraUI.clear(_detail)
    var data := AstraCaseCatalog.get_case(_selected_case)
    var accent := Color(str(data.get("accent", "80e4db")))
    var unlocked: bool = app.meta.is_case_unlocked(_selected_case)
    var hero := AstraUI.panel(AstraUI.PANEL, AstraUI.BORDER, 12, 0)
    hero.clip_contents = true
    hero.custom_minimum_size = Vector2(0, 246)
    _detail.add_child(hero)
    var portraits := AstraUI.hbox(3)
    hero.add_child(portraits)
    for id in ["mira", "sena", "noa", "lyra", "rho", "eli", "vale", "dax"]:
        var frame := Control.new()
        frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        frame.clip_contents = true
        portraits.add_child(frame)
        var art := AstraUI.thumb(AstraCrewCatalog.portrait_path(id), Vector2.ZERO)
        art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        frame.add_child(art)
        var shade := ColorRect.new()
        shade.color = Color(0.025, 0.045, 0.075, 0.85)
        shade.anchor_top = 0.82
        shade.anchor_bottom = 1.0
        shade.anchor_right = 1.0
        shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
        frame.add_child(shade)
        var name_label := AstraUI.label(id.to_upper(), 14, AstraUI.TEXT)
        name_label.anchor_top = 0.82
        name_label.anchor_bottom = 1.0
        name_label.anchor_right = 1.0
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        frame.add_child(name_label)
    var dossier := AstraUI.vbox(10)
    _detail.add_child(AstraUI.scroll(dossier))
    var meta_row := AstraUI.hbox(8)
    dossier.add_child(meta_row)
    meta_row.add_child(AstraUI.chip("CHAPTER %02d" % (AstraCaseCatalog.CAMPAIGN.find(_selected_case) + 1), accent))
    meta_row.add_child(AstraUI.label(str(data.get("theme", "")), 13, AstraUI.MUTED))
    meta_row.add_child(AstraUI.spacer())
    meta_row.add_child(AstraUI.label(app.meta.case_status(_selected_case), 13, AstraUI.GOLD if unlocked else AstraUI.DIM))
    dossier.add_child(AstraUI.label(str(data.get("title", "")), 34, AstraUI.TEXT))
    dossier.add_child(AstraUI.label(str(data.get("story_intro", data.get("card_line", ""))), 17, AstraUI.MUTED, true))
    var mission: Dictionary = data.get("mission", {})
    if not mission.is_empty():
        dossier.add_child(AstraUI.label("선택 임무  /  " + str(mission.get("title", "")), 14, accent, true))
    dossier.add_child(AstraUI.label(AstraCaseCatalog.CAMPAIGN_PREMISE, 13, AstraUI.DIM, true))
    dossier.add_child(AstraUI.label("흔적을 찾고  →  진술을 대조하고  →  숨어 있는 두 Null을 격리하세요", 13, AstraUI.DIM, true))
    _continue.text = "%s   →" % ("조사 시작 · " + str(data.get("title_ko", "")) if unlocked else app.meta.unlock_hint(_selected_case))
    _continue.disabled = not unlocked

func _refresh_protocols() -> void:
    AstraUI.clear(_protocol_row)
    for protocol_id in ["ANALYST", "EMPATH", "AUDITOR"]:
        var spec: Dictionary = AstraGameSession.PROTOCOLS[protocol_id]
        var selected: bool = app.selected_protocol == protocol_id
        var color := AstraUI.CYAN if selected else AstraUI.MUTED
        var card := AstraUI.button(("●  " if selected else "○  ") + str(spec.get("name", "")) + "   /   " + str(spec.get("summary", "")), color, 15, 60, selected)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        card.tooltip_text = str(spec.get("detail", ""))
        card.pressed.connect(func():
            app.selected_protocol = protocol_id
            app.fx.play("select")
            _refresh_protocols()
        )
        _protocol_row.add_child(card)

func _crew_archive() -> void:
    var grid := GridContainer.new()
    grid.columns = 4
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    for id in ["mira", "sena", "noa", "lyra", "rho", "eli", "vale", "dax"]:
        var info := AstraCrewCatalog.info(id)
        var card := AstraUI.vbox(5)
        card.custom_minimum_size = Vector2(204, 0)
        grid.add_child(card)
        card.add_child(AstraUI.thumb(AstraCrewCatalog.portrait_path(id), Vector2(204, 176)))
        card.add_child(AstraUI.label(AstraCrewCatalog.display_name(id) + "  ·  " + str(info.get("job", "")), 16, AstraCrewCatalog.accent(id)))
        card.add_child(AstraUI.label(str(info.get("concept", "")), 13, AstraUI.MUTED, true))
    var scroll := AstraUI.scroll(grid)
    scroll.custom_minimum_size = Vector2(0, 540)
    AstraModal.open(app.overlay_root(), "승무원 기록  /  누구를 믿을 것인가", scroll, [["닫기", AstraUI.CYAN]], Callable(), 940)

func _start_selected() -> void:
    if AstraGameSession.has_snapshot(app.snapshot_path()):
        var text := AstraUI.label("새 사건을 시작하면 자동 저장된 진행을 덮어씁니다. 완료한 사건 기록은 유지됩니다.", 16, AstraUI.TEXT, true)
        AstraModal.open(app.overlay_root(), "새 사건을 시작할까요?", text, [["취소", AstraUI.MUTED], ["새로 시작", AstraUI.CYAN]], func(choice: int):
            if choice == 1:
                app.start_case(_selected_case, app.selected_protocol)
        )
    else:
        app.start_case(_selected_case, app.selected_protocol)
