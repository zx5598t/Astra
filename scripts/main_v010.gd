extends "res://scripts/main_v009.gd"

const VERTICAL_VERSION := "0.1.0"
const PROTOCOL_ANALYST := "ANALYST"
const PROTOCOL_EMPATH := "EMPATH"
const PROTOCOL_AUDITOR := "AUDITOR"

var selected_protocol: String = PROTOCOL_ANALYST
var _protocol_applied_key: String = ""

func _reset_ui_refs() -> void:
    phase_label = null
    ap_label = null
    confidence_bar = null
    detail_box = null
    journal_box = null
    action_box = null
    npc_list = null
    evidence_list = null
    next_button = null
    selected_label = null
    score_label = null
    portrait_rect = null

func _show_title_screen() -> void:
    game = AstraGameState.new()
    notebook_open = false
    _reset_ui_refs()
    _clear_screen()
    _show_background()

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 42)
    margin.add_theme_constant_override("margin_right", 42)
    margin.add_theme_constant_override("margin_top", 28)
    margin.add_theme_constant_override("margin_bottom", 28)
    add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 14)
    margin.add_child(root)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 16)
    root.add_child(header)
    var title_stack := VBoxContainer.new()
    title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_stack)
    title_stack.add_child(_label("ASTRA // OBSERVER PROGRAM", 15, c_cyan))
    title_stack.add_child(_label("INCIDENT ARCHIVE", 44, c_text))
    title_stack.add_child(_label("0.1.0 VERTICAL SLICE · 사건을 조사하고, 가설을 제출하고, 다음 기록을 해금하라.", 16, c_muted))

    var archive := VBoxContainer.new()
    archive.custom_minimum_size = Vector2(360, 0)
    archive.add_child(_label(meta_progress.archive_rank(), 22, c_gold, true))
    archive.add_child(_label(meta_progress.campaign_summary(), 14, c_text, true))
    archive.add_child(_label("Insight %d · Best Theory %d" % [meta_progress.total_insight, meta_progress.best_theory_score], 13, c_muted, true))
    header.add_child(archive)

    var continue_button := _button("CONTINUE · %s" % meta_progress.case_display_name(meta_progress.recommended_case_id()), c_cyan)
    continue_button.custom_minimum_size = Vector2(0, 52)
    continue_button.pressed.connect(_launch_case.bind(meta_progress.recommended_case_id()))
    root.add_child(continue_button)

    root.add_child(_section_title("INVESTIGATOR PROTOCOL · 이번 사건에서 사용할 조사 방식"))
    var protocol_row := HBoxContainer.new()
    protocol_row.add_theme_constant_override("separation", 10)
    root.add_child(protocol_row)
    _add_protocol_button(protocol_row, PROTOCOL_ANALYST, "ANALYST", "현장 조사 행동력 +1", c_cyan)
    _add_protocol_button(protocol_row, PROTOCOL_EMPATH, "EMPATH", "심문 행동력 +1 · 초기 신뢰 소폭 상승", c_green)
    _add_protocol_button(protocol_row, PROTOCOL_AUDITOR, "AUDITOR", "사건 구조를 설명하는 기본 기록 1개 확보", c_gold)

    root.add_child(_section_title("INCIDENT BOARD · 사건은 순서대로 해금되며 언제든 클리어한 사건을 재조사할 수 있다"))
    var cases := HBoxContainer.new()
    cases.size_flags_vertical = Control.SIZE_EXPAND_FILL
    cases.add_theme_constant_override("separation", 12)
    root.add_child(cases)
    _add_case_card(cases, "DEAD_AIR", "INCIDENT ZERO", "DEAD AIR", "통신 두절 · 전력 우회", "함장 Ives의 죽음과 동시에 두 계통이 조작됐다.", c_cyan)
    _add_case_card(cases, "GLASS_GARDEN", "INCIDENT ONE", "GLASS GARDEN", "생명유지 · 수목구역 오염", "영양액과 정수 계통이 동시에 무너졌다.", c_green)
    _add_case_card(cases, "ECHO_WARD", "INCIDENT TWO", "ECHO WARD", "냉동수면 · 의료 기록 복제", "시간 공백 속에서 포드와 기록이 함께 조작됐다.", Color("ff9ed1"))

    var footer := HBoxContainer.new()
    footer.add_theme_constant_override("separation", 10)
    root.add_child(footer)
    var how := _button("HOW TO PLAY", c_panel)
    how.pressed.connect(_show_how_to_play)
    footer.add_child(how)
    var filler := Control.new()
    filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer.add_child(filler)
    var campaign_text := "FIRST ARCHIVE COMPLETE" if meta_progress.campaign_complete() else "NEXT GOAL · %s" % meta_progress.case_display_name(meta_progress.recommended_case_id())
    footer.add_child(_label(campaign_text, 14, c_gold))

func _add_protocol_button(parent: HBoxContainer, protocol_id: String, title: String, description: String, accent: Color) -> void:
    var text := "%s%s\n%s" % ["[SELECTED] " if selected_protocol == protocol_id else "", title, description]
    var button := _button(text, accent if selected_protocol == protocol_id else c_panel)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.custom_minimum_size = Vector2(0, 62)
    button.pressed.connect(_select_protocol.bind(protocol_id))
    parent.add_child(button)

func _select_protocol(protocol_id: String) -> void:
    if protocol_id not in [PROTOCOL_ANALYST, PROTOCOL_EMPATH, PROTOCOL_AUDITOR]:
        return
    selected_protocol = protocol_id
    _show_title_screen()

func _add_case_card(parent: HBoxContainer, case_id: String, incident_name: String, case_name: String, theme: String, description: String, accent: Color) -> void:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.custom_minimum_size = Vector2(360, 330)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(c_panel, 0.92)
    style.border_color = Color(accent, 0.62)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 16
    style.content_margin_bottom = 16
    panel.add_theme_stylebox_override("panel", style)
    parent.add_child(panel)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    panel.add_child(box)
    box.add_child(_label(incident_name, 13, accent))
    box.add_child(_label(case_name, 26, c_text))
    box.add_child(_label(theme, 14, c_muted))
    var desc := _label(description, 16, c_text)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(desc)

    var unlocked := meta_progress.is_case_unlocked(case_id)
    var status := meta_progress.case_status(case_id)
    var status_color := c_green if status.begins_with("CLEARED") else (c_gold if unlocked else c_muted)
    box.add_child(_label(status, 14, status_color))
    var best := meta_progress.best_case_score(case_id)
    if best >= 0:
        box.add_child(_label("CASE THEORY BEST · %d / 100" % best, 13, c_gold))
    elif not unlocked:
        box.add_child(_label(_unlock_hint(case_id), 13, c_muted))

    var launch := _button("조사 시작" if unlocked else "LOCKED", accent if unlocked else c_panel)
    launch.disabled = not unlocked
    launch.custom_minimum_size = Vector2(0, 46)
    if unlocked:
        launch.pressed.connect(_launch_case.bind(case_id))
    box.add_child(launch)

func _unlock_hint(case_id: String) -> String:
    if case_id == "GLASS_GARDEN":
        return "Dead Air 사건을 1회 완료하면 해금"
    if case_id == "ECHO_WARD":
        return "Glass Garden 사건을 1회 완료하면 해금"
    return ""

func _show_how_to_play() -> void:
    game = AstraGameState.new()
    _reset_ui_refs()
    _clear_screen()
    _show_background()
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var panel := VBoxContainer.new()
    panel.custom_minimum_size = Vector2(980, 700)
    panel.add_theme_constant_override("separation", 12)
    center.add_child(panel)
    panel.add_child(_label("ASTRA 0.1.0 · HOW TO PLAY", 36, c_text, true))
    var body := RichTextLabel.new()
    body.bbcode_enabled = true
    body.fit_content = false
    body.custom_minimum_size = Vector2(960, 545)
    body.add_theme_font_size_override("normal_font_size", 18)
    body.text = "[font_size=22][color=#55d6ff]1. 사건과 Protocol을 고른다[/color][/font_size]\nDead Air부터 시작해 사건을 완료하면 다음 Incident가 해금됩니다. ANALYST는 조사, EMPATH는 심문, AUDITOR는 초기 기록 확보에 강점이 있습니다.\n\n[font_size=22][color=#55d6ff]2. 현장 조사와 개인 심문[/color][/font_size]\n행동력은 한정되어 있습니다. 모든 장소와 모든 사람을 전부 확인할 수 없으므로 어떤 정보를 먼저 볼지 선택해야 합니다.\n\n[font_size=22][color=#55d6ff]3. Investigator Notebook[/color][/font_size]\n확보한 증거를 Crew에 직접 연결해 suspect / clear / question 가설을 만듭니다. 게임은 이 연결을 정답으로 강제하지 않습니다.\n\n[font_size=22][color=#55d6ff]4. 공개 회의와 CASE THEORY[/color][/font_size]\nNPC의 발언은 각자의 기억·관계·의심을 반영합니다. 투표 전에 반드시 두 명의 용의자와 확신도를 제출합니다.\n\n[font_size=22][color=#55d6ff]5. 사건 종료 후 평가[/color][/font_size]\n실제 Null 적중, 증거 연결, 모순 활용, 확신도 보정을 합산해 0~100점으로 평가합니다. 사건별 최고 점수는 Archive에 보존됩니다.\n\n[color=#ffd36a]핵심: 스트레스가 높은 사람 = 범인이라는 공식은 없습니다. 기록, 동선, 모순, 발언의 변화를 함께 보세요.[/color]"
    panel.add_child(body)
    var back := _button("← INCIDENT ARCHIVE", c_panel)
    back.pressed.connect(_show_title_screen)
    panel.add_child(back)

func _launch_case(preferred: String = "") -> void:
    if preferred != "" and not meta_progress.is_case_unlocked(preferred):
        _show_title_screen()
        return
    _protocol_applied_key = ""
    super._launch_case(preferred)
    _apply_selected_protocol()
    _refresh()

func _apply_selected_protocol() -> void:
    var hypothesis = _hypothesis_game()
    if hypothesis == null:
        return
    var key := "%d:%s:%s" % [hypothesis.seed_value, hypothesis.case_id, selected_protocol]
    if key == _protocol_applied_key:
        return
    _protocol_applied_key = key

    match selected_protocol:
        PROTOCOL_ANALYST:
            hypothesis.investigation_actions_left += 1
            hypothesis.log_event("PROTOCOL · ANALYST · investigation AP +1")
        PROTOCOL_EMPATH:
            hypothesis.talk_actions_left += 1
            for npc_id in hypothesis.crew_order:
                if npc_id in hypothesis.npcs and hypothesis.npcs[npc_id].alive:
                    hypothesis.npcs[npc_id].adjust_trust(0.02)
            hypothesis.log_event("PROTOCOL · EMPATH · interrogation AP +1 / initial trust +2%")
        PROTOCOL_AUDITOR:
            var starter_evidence := _starter_context_evidence(hypothesis)
            if starter_evidence != "":
                hypothesis.discovered_evidence.append(starter_evidence)
                hypothesis.case_confidence = maxf(hypothesis.case_confidence, 0.08)
                hypothesis.log_event("PROTOCOL · AUDITOR · %s 확보" % hypothesis.truth.evidence_name(starter_evidence))
    hypothesis.emit_signal("state_changed")

func _starter_context_evidence(hypothesis) -> String:
    var ids: Array = hypothesis.truth.evidence.keys()
    ids.sort()
    for raw_id in ids:
        var ev_id := str(raw_id)
        var ev: Dictionary = hypothesis.truth.evidence.get(ev_id, {})
        var evidence_signal := str(ev.get("signal", ""))
        if str(ev.get("rarity", "COMMON")) == "COMMON" and evidence_signal == "context":
            return ev_id
    return ""

func _record_theory_meta_if_needed(hypothesis) -> void:
    if theory_model == null or not hypothesis.game_over or theory_model.final_result.is_empty():
        return
    var key := "%d:%s" % [hypothesis.seed_value, hypothesis.case_id]
    if key == _theory_meta_recorded_key:
        return
    _theory_meta_recorded_key = key
    meta_progress.record_theory_result(theory_model.final_result, hypothesis.case_id)

func _start_next_case() -> void:
    var hypothesis = _hypothesis_game()
    if hypothesis == null:
        _show_title_screen()
        return
    var next_id := _next_campaign_case(hypothesis.case_id)
    if next_id == "":
        _show_title_screen()
        return
    _launch_case(next_id)

func _next_campaign_case(current_id: String) -> String:
    var index := AstraMetaProgress.CAMPAIGN_CASES.find(current_id)
    if index >= 0:
        for i in range(index + 1, AstraMetaProgress.CAMPAIGN_CASES.size()):
            var candidate := str(AstraMetaProgress.CAMPAIGN_CASES[i])
            if meta_progress.is_case_unlocked(candidate):
                return candidate
    return meta_progress.recommended_case_id()

func _refresh_actions() -> void:
    super._refresh_actions()
    var hypothesis = _hypothesis_game()
    if hypothesis == null or action_box == null:
        return
    if hypothesis.phase_name() == "RESULT":
        _add_info("VERTICAL SLICE · %s · %s" % [meta_progress.case_status(hypothesis.case_id), meta_progress.campaign_summary()])
        var next_id := _next_campaign_case(hypothesis.case_id)
        if next_id != "" and next_id != hypothesis.case_id and meta_progress.is_case_unlocked(next_id):
            _add_info("NEXT INCIDENT UNLOCKED · %s" % meta_progress.case_display_name(next_id))
        elif meta_progress.campaign_complete():
            _add_info("FIRST ARCHIVE COMPLETE · 세 사건을 모두 완료했습니다. 더 높은 CASE THEORY 점수를 노릴 수 있습니다.")
        _add_action("INCIDENT ARCHIVE로 돌아가기", c_cyan, _show_title_screen, "사건별 기록과 해금 상태 확인")
        _add_action("같은 사건 재조사", c_panel, _launch_case.bind(hypothesis.case_id), "새 Seed · Null과 증거 대상 재배치")

func _refresh() -> void:
    super._refresh()
    var hypothesis = _hypothesis_game()
    if hypothesis == null:
        return
    if ap_label != null:
        var protocol_name := selected_protocol
        if hypothesis.phase_name() == "INVESTIGATION":
            ap_label.text = "조사 행동력 %d · %s" % [hypothesis.investigation_actions_left, protocol_name]
        elif hypothesis.phase_name() == "INTERROGATION":
            ap_label.text = "심문 행동력 %d · %s" % [hypothesis.talk_actions_left, protocol_name]
        else:
            ap_label.text += " · %s" % protocol_name
    if score_label != null:
        score_label.text = "SCORE %04d · %s · %d/3" % [hypothesis.score, meta_progress.archive_rank(), meta_progress.completed_campaign_cases()]
