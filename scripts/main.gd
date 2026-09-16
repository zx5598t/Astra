extends Control

const StarfieldScript = preload("res://scripts/starfield.gd")

var game := AstraGameState.new()
var phase_label: Label
var ap_label: Label
var confidence_bar: ProgressBar
var detail_box: RichTextLabel
var journal_box: RichTextLabel
var action_box: VBoxContainer
var npc_list: VBoxContainer
var evidence_list: VBoxContainer
var next_button: Button
var selected_label: Label
var score_label: Label

var c_bg := Color("07101f")
var c_panel := Color("101b2e")
var c_border := Color("29405f")
var c_text := Color("e8f1ff")
var c_muted := Color("8ea5c5")
var c_cyan := Color("55d6ff")
var c_green := Color("5ee3a0")
var c_red := Color("ff6f7f")
var c_gold := Color("ffd36a")

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _show_title_screen()

func _clear_screen() -> void:
    for child in get_children():
        child.queue_free()

func _show_title_screen() -> void:
    _clear_screen()
    var bg := ColorRect.new()
    bg.color = c_bg
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var stars := StarfieldScript.new()
    stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(stars)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var card := VBoxContainer.new()
    card.custom_minimum_size = Vector2(720, 0)
    card.add_theme_constant_override("separation", 16)
    center.add_child(card)

    var kicker := _label("ASTRA // SIGNAL LOST", 16, c_cyan)
    kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    card.add_child(kicker)

    var title := _label("INCIDENT ZERO", 56, c_text)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    card.add_child(title)

    var subtitle := _label("DEAD AIR", 24, c_muted)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    card.add_child(subtitle)

    card.add_child(HSeparator.new())

    var desc := _label("함장이 죽었다. 여섯 명의 승무원. 두 명의 Null.\n모두가 같은 진실을 알고 있는 것은 아니다.", 22, c_text)
    desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    card.add_child(desc)

    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(0, 12)
    card.add_child(spacer)

    var start := _button("▶  INCIDENT ZERO 시작", c_cyan)
    start.custom_minimum_size = Vector2(0, 58)
    start.pressed.connect(_start_game)
    card.add_child(start)

    var tutorial := _button("?  플레이 방법", c_panel)
    tutorial.custom_minimum_size = Vector2(0, 48)
    tutorial.pressed.connect(_show_how_to_play)
    card.add_child(tutorial)

    var ver := _label("v0.0.2 · Offline rules simulation · AI-ready", 14, c_muted)
    ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    card.add_child(ver)

func _show_how_to_play() -> void:
    _clear_screen()
    var bg := ColorRect.new()
    bg.color = c_bg
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var stars := StarfieldScript.new()
    stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(stars)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var panel := VBoxContainer.new()
    panel.custom_minimum_size = Vector2(860, 620)
    panel.add_theme_constant_override("separation", 14)
    center.add_child(panel)
    var title := _label("HOW TO PLAY", 38, c_text)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    panel.add_child(title)
    var body := RichTextLabel.new()
    body.bbcode_enabled = true
    body.fit_content = false
    body.custom_minimum_size = Vector2(840, 440)
    body.text = "[font_size=22][color=#55d6ff]1. 현장 조사[/color][/font_size]\n행동력 3을 사용해 의료실·엔진실·통신실에서 증거를 찾습니다.\n\n[font_size=22][color=#55d6ff]2. 개인 심문[/color][/font_size]\n승무원을 선택하고 알리바이, 동기, 증거 제시, 회유, 압박 중 하나를 사용합니다. 반응은 신뢰와 스트레스에 영향을 줍니다.\n\n[font_size=22][color=#55d6ff]3. 공개 회의[/color][/font_size]\nNPC들이 현재 믿음을 바탕으로 서로를 의심합니다. 오른쪽 CASE LOG와 증거 목록을 비교하세요.\n\n[font_size=22][color=#55d6ff]4. 격리 투표[/color][/font_size]\n한 명을 골라 격리합니다. Null을 맞히면 보너스 점수를 얻습니다.\n\n[color=#8ea5c5]TIP · 긴장했다는 이유만으로 적은 아닙니다. 인물의 주장과 실제 기록의 모순을 찾으세요.[/color]"
    panel.add_child(body)
    var back := _button("← 타이틀로", c_panel)
    back.pressed.connect(_show_title_screen)
    panel.add_child(back)

func _start_game() -> void:
    game = AstraGameState.new()
    game.state_changed.connect(_refresh)
    var seed := int(Time.get_unix_time_from_system()) % 1000000
    game.setup(seed)
    _build_game_ui()
    _refresh()

func _build_game_ui() -> void:
    _clear_screen()
    var bg := ColorRect.new()
    bg.color = c_bg
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var stars := StarfieldScript.new()
    stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(stars)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 12)
    margin.add_child(root)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 16)
    root.add_child(header)
    header.add_child(_label("ASTRA", 30, c_text))
    var case_name := _label("INCIDENT ZERO · DEAD AIR", 17, c_muted)
    case_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(case_name)
    score_label = _label("SCORE 0000", 18, c_gold)
    header.add_child(score_label)

    var status_panel := HBoxContainer.new()
    status_panel.add_theme_constant_override("separation", 14)
    root.add_child(status_panel)
    phase_label = _label("", 20, c_cyan)
    phase_label.custom_minimum_size = Vector2(240, 34)
    status_panel.add_child(phase_label)
    ap_label = _label("", 16, c_muted)
    ap_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status_panel.add_child(ap_label)
    status_panel.add_child(_label("CASE", 14, c_muted))
    confidence_bar = ProgressBar.new()
    confidence_bar.custom_minimum_size = Vector2(170, 18)
    confidence_bar.max_value = 100.0
    confidence_bar.show_percentage = false
    status_panel.add_child(confidence_bar)

    var main_columns := HBoxContainer.new()
    main_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main_columns.add_theme_constant_override("separation", 12)
    root.add_child(main_columns)

    var left_panel := _panel_vbox(300)
    main_columns.add_child(left_panel)
    left_panel.add_child(_section_title("CREW MANIFEST"))
    selected_label = _label("SELECTED · MIRA", 13, c_cyan)
    left_panel.add_child(selected_label)
    npc_list = VBoxContainer.new()
    npc_list.add_theme_constant_override("separation", 7)
    left_panel.add_child(npc_list)

    var center_panel := _panel_vbox(0)
    center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_columns.add_child(center_panel)
    center_panel.add_child(_section_title("TACTICAL VIEW"))
    detail_box = RichTextLabel.new()
    detail_box.bbcode_enabled = true
    detail_box.fit_content = false
    detail_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    detail_box.custom_minimum_size = Vector2(500, 320)
    detail_box.add_theme_font_size_override("normal_font_size", 18)
    center_panel.add_child(detail_box)
    center_panel.add_child(_section_title("AVAILABLE ACTIONS"))
    var action_scroll := ScrollContainer.new()
    action_scroll.custom_minimum_size = Vector2(0, 220)
    center_panel.add_child(action_scroll)
    action_box = VBoxContainer.new()
    action_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    action_box.add_theme_constant_override("separation", 8)
    action_scroll.add_child(action_box)

    var right_panel := _panel_vbox(360)
    main_columns.add_child(right_panel)
    right_panel.add_child(_section_title("EVIDENCE"))
    var ev_scroll := ScrollContainer.new()
    ev_scroll.custom_minimum_size = Vector2(0, 220)
    right_panel.add_child(ev_scroll)
    evidence_list = VBoxContainer.new()
    evidence_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    evidence_list.add_theme_constant_override("separation", 6)
    ev_scroll.add_child(evidence_list)
    right_panel.add_child(_section_title("CASE LOG"))
    journal_box = RichTextLabel.new()
    journal_box.bbcode_enabled = true
    journal_box.scroll_following = true
    journal_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    journal_box.add_theme_font_size_override("normal_font_size", 14)
    right_panel.add_child(journal_box)

    var footer := HBoxContainer.new()
    footer.add_theme_constant_override("separation", 10)
    root.add_child(footer)
    var quit := _button("← 타이틀", c_panel)
    quit.pressed.connect(_show_title_screen)
    footer.add_child(quit)
    var restart := _button("↻ 새 사건", c_panel)
    restart.pressed.connect(_start_game)
    footer.add_child(restart)
    var grow := Control.new()
    grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer.add_child(grow)
    next_button = _button("다음 단계  →", c_cyan)
    next_button.custom_minimum_size = Vector2(220, 46)
    next_button.pressed.connect(_advance)
    footer.add_child(next_button)

func _panel_vbox(min_width: int) -> VBoxContainer:
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    if min_width > 0:
        box.custom_minimum_size = Vector2(min_width, 0)
    return box

func _section_title(text: String) -> Label:
    return _label(text, 14, c_cyan)

func _label(text: String, size_px: int, color: Color) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size_px)
    l.add_theme_color_override("font_color", color)
    return l

func _button(text: String, accent: Color) -> Button:
    var b := Button.new()
    b.text = text
    b.add_theme_font_size_override("font_size", 16)
    b.add_theme_color_override("font_color", c_text)
    b.add_theme_color_override("font_hover_color", Color.WHITE)
    b.custom_minimum_size = Vector2(0, 42)
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(accent, 0.16) if accent != c_panel else Color(c_panel, 0.9)
    normal.border_color = Color(accent, 0.72) if accent != c_panel else c_border
    normal.set_border_width_all(1)
    normal.set_corner_radius_all(7)
    normal.content_margin_left = 12
    normal.content_margin_right = 12
    var hover := normal.duplicate()
    hover.bg_color = Color(accent, 0.30) if accent != c_panel else Color("182942")
    var pressed := normal.duplicate()
    pressed.bg_color = Color(accent, 0.42) if accent != c_panel else Color("223654")
    b.add_theme_stylebox_override("normal", normal)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", pressed)
    return b

func _refresh() -> void:
    if phase_label == null:
        return
    phase_label.text = "DAY %d · %s" % [game.day, game.phase_display_name()]
    score_label.text = "SCORE %04d" % game.score
    confidence_bar.value = game.case_confidence * 100.0
    match game.phase_name():
        "INVESTIGATION": ap_label.text = "조사 행동력  %d / %d" % [game.investigation_actions_left, AstraGameState.INVESTIGATION_ACTIONS]
        "INTERROGATION": ap_label.text = "심문 행동력  %d / %d" % [game.talk_actions_left, AstraGameState.TALK_ACTIONS]
        "VOTE": ap_label.text = "최종 판단 · 한 명을 격리"
        "RESULT": ap_label.text = "사건 종료"
        _: ap_label.text = "Seed %d" % game.seed_value
    _refresh_npcs()
    _refresh_evidence()
    _refresh_journal()
    _refresh_actions()
    next_button.disabled = not game.can_advance_phase()
    next_button.text = "사건 종료" if game.phase_name() == "RESULT" else "다음 단계  →"

func _refresh_npcs() -> void:
    for child in npc_list.get_children():
        child.queue_free()
    for npc_id in ["mira", "rho", "eli", "sena", "vale", "noa"]:
        var npc: NPCState = game.npcs[npc_id]
        var b := _button("%s  ·  %s" % [npc.display_name, npc.job], npc.accent)
        if game.selected_npc_id == npc_id:
            b.text = "◆  " + b.text
        var stress := int(float(npc.emotion.get("stress", 0.2)) * 100.0)
        b.tooltip_text = "신뢰 %d%% · 스트레스 %d%% · 기억 %d" % [int(npc.trust_player * 100.0), stress, npc.memories.size()]
        b.pressed.connect(_select_npc.bind(npc_id))
        npc_list.add_child(b)

func _refresh_evidence() -> void:
    for child in evidence_list.get_children():
        child.queue_free()
    if game.discovered_evidence.is_empty():
        var none := _label("아직 확보한 증거가 없다.", 14, c_muted)
        none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        evidence_list.add_child(none)
        return
    for ev_id in game.discovered_evidence:
        var ev: Dictionary = game.truth.evidence[ev_id]
        var key := str(ev.get("rarity", "COMMON")) == "KEY"
        var line := _label(("◆ " if key else "• ") + str(ev["name"]), 14, c_gold if key else c_text)
        line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        line.tooltip_text = game.truth.fact_text(str(ev["fact_ref"]))
        evidence_list.add_child(line)

func _refresh_journal() -> void:
    var lines: Array[String] = []
    var start := maxi(0, game.journal.size() - 16)
    for i in range(start, game.journal.size()):
        lines.append("[color=#6f86a8]%02d[/color]  %s" % [i + 1, game.journal[i]])
    journal_box.text = "\n\n".join(lines)

func _refresh_actions() -> void:
    for child in action_box.get_children():
        child.queue_free()
    match game.phase_name():
        "BRIEFING":
            detail_box.text = "[color=#55d6ff][font_size=28]INCIDENT ZERO[/font_size][/color]\n[color=#8ea5c5]DEAD AIR[/color]\n\n07:38, 함장 Ives가 자신의 선실에서 사망한 채 발견됐다. 직전 90초 동안 함선 전력과 외부 통신에 동시에 이상이 발생했다.\n\n[b]MISSION[/b] · 증거와 증언을 대조해 Null 침투자 한 명을 격리하라.\n\n[color=#ffd36a]승무원 6명 · Crew 4 · Null 2[/color]"
            _add_info("브리핑을 확인했다면 현장 조사로 이동하세요.")
        "INVESTIGATION":
            detail_box.text = "[font_size=24][color=#55d6ff]현장 조사[/color][/font_size]\n\n행동력은 3뿐이다. 같은 구역을 반복 조사할 수도 있지만 아무것도 찾지 못할 수 있다.\n\n현재 위치 · [b]%s[/b]" % game.selected_location
            _add_action("✚  의료실 조사", c_cyan, _investigate.bind("의료실"), "출입 로그와 생체 기록")
            _add_action("⚙  엔진실 조사", c_gold, _investigate.bind("엔진실"), "전력·냉각 제어 기록")
            _add_action("⌁  통신실 조사", c_green, _investigate.bind("통신실"), "권한·외부 패킷 기록")
        "INTERROGATION":
            var npc: NPCState = game.npcs[game.selected_npc_id]
            _show_npc_profile(npc)
            _add_action("알리바이를 묻는다", npc.accent, _talk.bind("ALIBI"), "공식적인 시간대 주장")
            _add_action("동기를 묻는다", npc.accent, _talk.bind("MOTIVE"), "함장과의 관계 확인")
            _add_action("최근 증거를 제시한다", c_gold, _talk.bind("EVIDENCE"), "반응과 모순 확인")
            _add_action("안심시키며 회유한다", c_green, _talk.bind("REASSURE"), "신뢰 상승 가능")
            _add_action("강하게 압박한다", c_red, _talk.bind("PRESSURE"), "스트레스 상승 · 신뢰 하락")
        "MEETING":
            detail_box.text = "[font_size=24][color=#55d6ff]공개 회의[/color][/font_size]\n\n모든 승무원이 현재 믿음에 따라 한 명을 가장 의심하고 있다. 이것은 정답이 아니라 각자의 판단이다.\n\n"
            for line in game.meeting_summary:
                detail_box.append_text("• %s\n" % line)
            _add_info("마지막으로 원하는 승무원에게 공개 질문을 던질 수 있습니다. 행동력 제한은 없습니다.")
            _add_action("선택 인물에게 공개 알리바이 요구", c_cyan, _talk.bind("ALIBI"), "모두가 듣는 앞에서 주장 고정")
            _add_action("선택 인물에게 최근 증거 제시", c_gold, _talk.bind("EVIDENCE"), "공개 반응 확인")
        "VOTE":
            detail_box.text = "[font_size=28][color=#ff6f7f]격리 투표[/color][/font_size]\n\n확보한 증거와 승무원들의 말을 비교해 한 명을 선택하라.\n\n[color=#8ea5c5]주의 · NPC의 의심도는 각자의 믿음일 뿐 실제 정답을 보장하지 않는다.[/color]"
            for npc_id in ["mira", "rho", "eli", "sena", "vale", "noa"]:
                var npc: NPCState = game.npcs[npc_id]
                _add_action("%s · %s 격리" % [npc.display_name, npc.job], c_red, _vote.bind(npc_id), "결정을 되돌릴 수 없음")
        "RESULT":
            var result_color := "#5ee3a0" if game.result_title == "NULL IDENTIFIED" else "#ff6f7f"
            detail_box.text = "[center][font_size=34][color=%s]%s[/color][/font_size]\n\n[font_size=20]%s[/font_size]\n\n[color=#ffd36a]FINAL SCORE · %d[/color]\n증거 확보 · %d / 6[/center]" % [result_color, game.result_title, game.ending_text, game.score, game.discovered_evidence.size()]
            _add_action("같은 사건을 새 Seed로 재도전", c_cyan, _start_game, "증거 발견 순서와 NPC 의심도가 달라짐")
            _add_action("타이틀로 돌아가기", c_panel, _show_title_screen, "")

func _show_npc_profile(npc: NPCState) -> void:
    selected_label.text = "SELECTED · %s" % npc.display_name.to_upper()
    var stress := int(float(npc.emotion.get("stress", 0.2)) * 100.0)
    var known_claims := "없음" if npc.commitments.is_empty() else npc.commitments[-1]
    detail_box.text = "[font_size=28][color=#%s]%s[/color][/font_size]  [color=#8ea5c5]%s[/color]\n\n신뢰도  [b]%d%%[/b]     스트레스  [b]%d%%[/b]\n기억  %d건     공개 주장  %d건\n\n[color=#8ea5c5]최근 고정된 주장[/color]\n%s" % [npc.accent.to_html(false), npc.display_name, npc.job, int(npc.trust_player * 100.0), stress, npc.memories.size(), npc.commitments.size(), known_claims]

func _add_action(text: String, accent: Color, callable: Callable, hint: String = "") -> void:
    var row := VBoxContainer.new()
    var b := _button(text, accent)
    b.pressed.connect(callable)
    row.add_child(b)
    if hint != "":
        row.add_child(_label(hint, 12, c_muted))
    action_box.add_child(row)

func _add_info(text: String) -> void:
    var l := _label(text, 15, c_muted)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    action_box.add_child(l)

func _select_npc(npc_id: String) -> void:
    game.selected_npc_id = npc_id
    var npc: NPCState = game.npcs[npc_id]
    selected_label.text = "SELECTED · %s" % npc.display_name.to_upper()
    if game.phase_name() in ["INTERROGATION", "MEETING"]:
        _refresh_actions()
    else:
        _show_npc_profile(npc)
    _refresh_npcs()

func _investigate(location: String) -> void:
    var result := game.investigate(location)
    detail_box.text = "[font_size=24][color=#ffd36a]%s[/color][/font_size]\n\n%s\n\n[color=#8ea5c5]남은 조사 행동력 · %d[/color]" % [location, result, game.investigation_actions_left]

func _talk(intent: String) -> void:
    var npc: NPCState = game.npcs[game.selected_npc_id]
    var response := game.talk_to(game.selected_npc_id, intent)
    detail_box.text = "[font_size=28][color=#%s]%s[/color][/font_size]\n[color=#8ea5c5]%s[/color]\n\n\"%s\"" % [npc.accent.to_html(false), npc.display_name, npc.job, response]

func _vote(npc_id: String) -> void:
    game.vote(npc_id)

func _advance() -> void:
    game.advance_phase()
