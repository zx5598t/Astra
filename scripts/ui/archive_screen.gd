class_name AstraArchiveScreen
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
    progress.add_child(AstraUI.label(app.meta.campaign_summary(), 13, AstraUI.MUTED))

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

    # The protocol picker is a 0.4.0 unlock. Asking a player to choose between
    # three investigation styles before they have investigated anything is a
    # question with no information behind it (§6).
    _protocol_row = AstraUI.hbox(12)
    if app.meta.has_feature("protocols"):
        root.add_child(AstraUI.section("나의 조사 방식  /  선택한 능력은 이 사건 동안 유지됩니다"))
        root.add_child(_protocol_row)
        _refresh_protocols()
    var footer := AstraUI.hbox(10)
    root.add_child(footer)
    _continue = AstraUI.button("", AstraUI.CYAN, 19, 56, true)
    _continue.custom_minimum_size = Vector2(410, 56)
    _continue.pressed.connect(_start_selected)
    footer.add_child(_continue)
    for row in app.slot_infos():
        if bool(row["empty"]):
            continue
        var slot := int(row["slot"])
        var info: Dictionary = row["info"]
        var resume := AstraUI.button("%d번 이어하기 · %d일째" % [slot + 1, int(info.get("day", 1))], AstraUI.GREEN, AstraUI.T_UI, 56, true)
        resume.pressed.connect(func(): app.resume_case(slot))
        footer.add_child(resume)
    var back := AstraUI.button("타이틀", AstraUI.MUTED, 14, 46)
    back.pressed.connect(func(): app.show_title())
    footer.add_child(back)
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
    hero.custom_minimum_size = Vector2(0, 210)
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
        var name_label := AstraUI.label(AstraCrewCatalog.display_name(id), 14, AstraUI.TEXT)
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
    dossier.add_child(AstraUI.prose(AstraCaseCatalog.CAMPAIGN_PREMISE, AstraUI.T_META, AstraUI.MUTED))
    dossier.add_child(AstraUI.label(_case_goal_line(_selected_case), 13, AstraUI.DIM, true))
    _continue.text = "%s   →" % ("조사 시작 · " + str(data.get("title_ko", "")) if unlocked else app.meta.unlock_hint(_selected_case))
    _continue.disabled = not unlocked

func _case_goal_line(case_id: String) -> String:
    match case_id:
        "DEAD_AIR":
            return "서로 다른 목적지 기록의 출처를 확인하세요."
        "GLASS_GARDEN":
            return "세나와 준의 서로 다른 근무 기록을 대조하세요."
        "ECHO_WARD":
            return "신호 기록을 확인하고, 처음으로 장기수면 격리 판단을 내립니다."
        "SILENT_ORBIT":
            return "항법 기록과 오래된 도착 기록을 대조하세요."
        "RED_SHIFT":
            return "겹치는 기록과 관계의 변화를 함께 확인하세요."
        "LAST_LIGHT":
            return "남은 기록을 연결해 ASTRA의 항해가 왜 반복되는지 확인하세요."
    return str(AstraCaseCatalog.get_case(case_id).get("card_line", "기록과 기억이 어긋난 이유를 확인하세요."))

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
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 14)
    grid.add_theme_constant_override("v_separation", 14)
    for id in ["mira", "sena", "noa", "lyra", "rho", "eli", "vale", "dax"]:
        var info := AstraCrewCatalog.info(id)
        var card_panel := AstraUI.panel(AstraUI.PANEL_2,Color(AstraCrewCatalog.accent(id),0.25),10,12)
        card_panel.custom_minimum_size = Vector2(414,0)
        grid.add_child(card_panel)
        var card := AstraUI.vbox(6)
        card_panel.add_child(card)
        var hero := AstraUI.hbox(10)
        card.add_child(hero)
        hero.add_child(AstraUI.thumb(AstraCrewCatalog.portrait_path(id), Vector2(92,112)))
        var title := AstraUI.vbox(3)
        title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hero.add_child(title)
        title.add_child(AstraUI.label(AstraCrewCatalog.display_name(id),20,AstraCrewCatalog.accent(id)))
        title.add_child(AstraUI.label(str(info.get("job","")),13,AstraUI.MUTED,true))
        var entries: Array = app.meta.codex_entries_for(id)
        title.add_child(AstraUI.label("관찰 기록 %d개" % entries.size(),12,AstraUI.CYAN))
        if entries.is_empty():
            card.add_child(AstraUI.prose("아직 직접 기록한 관찰이 없습니다. 함께 항해하며 실제로 본 모습만 여기에 남습니다.",AstraUI.T_META,AstraUI.DIM))
        else:
            for entry in entries:
                var scope := str(entry.get("scope","OBSERVED"))
                var scope_label: String = str({"STABLE":"평소의 모습","OBSERVED":"관찰한 기록","ECHO":"잔향"}.get(scope,scope))
                var heading := "%s · %s" % [scope_label,str(entry.get("title",""))]
                card.add_child(AstraUI.label(heading,AstraUI.T_META,AstraUI.GOLD if scope=="ECHO" else AstraUI.CYAN))
                card.add_child(AstraUI.prose(str(entry.get("body","")),AstraUI.T_META,AstraUI.TEXT))
    var scroll := AstraUI.scroll(grid)
    scroll.custom_minimum_size = Vector2(0, 560)
    AstraModal.open(app.overlay_root(), "승무원 기록  /  내가 실제로 본 것", scroll, [["닫기", AstraUI.CYAN]], Callable(), 940)

# With three slots a new case does not overwrite anything unless all three are
# full, so the old "this will erase your progress" warning is gone.
func _start_selected() -> void:
    var free_slot: int = app.first_free_slot()
    if free_slot >= 0:
        app.start_case(_selected_case, app.selected_protocol, free_slot)
        return
    var text := AstraUI.prose("저장 슬롯 세 개가 모두 차 있습니다. 타이틀 화면에서 자리를 하나 비우거나 덮어쓸 자리를 고르세요.", AstraUI.T_BODY, AstraUI.TEXT)
    AstraModal.open(app.overlay_root(), "빈 저장 자리가 없습니다", text, [["타이틀로", AstraUI.CYAN]], func(_choice: int): app.show_title(), 560.0)
