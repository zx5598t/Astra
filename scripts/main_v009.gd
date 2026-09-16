extends "res://scripts/main_v008.gd"

const DeductionStateScript = preload("res://scripts/deduction_game_state.gd")
const TheoryPanelScript = preload("res://scripts/case_theory_panel.gd")
const IncidentStageScript = preload("res://scripts/incident_stage.gd")

var _theory_meta_recorded_key: String = ""

func _replace_version_label(node: Node) -> void:
    if node is Label:
        var label := node as Label
        if label.text.begins_with("0.0.3") or label.text.begins_with("0.0.4") or label.text.begins_with("0.0.5") or label.text.begins_with("0.0.6") or label.text.begins_with("0.0.7") or label.text.begins_with("0.0.8"):
            label.text = "0.0.9 · Case Theory Review · Cinematic Incident Stage · Expanded Private Events · %s" % meta_progress.archive_rank()
        elif label.text == "ASTRA // OBSERVER ARCHIVE":
            label.text = "ASTRA // CASE ANALYSIS"
    for child in node.get_children():
        _replace_version_label(child)

func _launch_case(preferred: String = "") -> void:
    notebook_open = false
    _meeting_ai_day = -1
    _meeting_ai_queue.clear()
    _meeting_ai_inflight = false
    _last_relationship_event_count = 0
    _meta_recorded_key = ""
    _theory_meta_recorded_key = ""
    _last_personal_result = ""
    game = DeductionStateScript.new()
    game.preferred_case_id = preferred
    game.state_changed.connect(_refresh)
    var seed: int = int(Time.get_unix_time_from_system()) % 1000000
    game.setup(seed)
    _build_game_ui()
    _install_ai_client_v006()
    _install_feedback_fx()
    _refresh()
    if feedback_fx != null:
        feedback_fx.flash(c_cyan, 0.10)

func _deduction_game():
    return game

func _refresh_actions() -> void:
    var deduction = _deduction_game()
    if deduction == null:
        super._refresh_actions()
        return
    if notebook_open:
        super._refresh_actions()
        return
    if not deduction.pending_personal_event.is_empty():
        _show_personal_event(deduction)
        return
    if deduction.phase_name() == "VOTE":
        _show_theory_vote_gate(deduction)
        return

    super._refresh_actions()

    if deduction.phase_name() == "BRIEFING" and deduction.day == 1:
        _install_incident_stage(deduction)

    if deduction.phase_name() == "RESULT":
        var review: String = str(deduction.final_theory_bbcode())
        if review != "":
            detail_box.append_text("\n\n" + review)
        _record_theory_meta_if_needed(deduction)
        _add_info("DEDUCTION ARCHIVE · theories %d · perfect %d · best %d" % [meta_progress.theories_submitted, meta_progress.perfect_theories, meta_progress.best_theory_score])

func _install_incident_stage(deduction) -> void:
    var stage = IncidentStageScript.new()
    stage.configure(deduction)
    action_box.add_child(stage)
    action_box.move_child(stage, 0)

func _show_theory_vote_gate(deduction) -> void:
    for child in action_box.get_children():
        child.queue_free()
    _show_selected_profile()
    detail_box.append_text("\n\n[font_size=24][color=#ffd36a]CASE THEORY GATE[/color][/font_size]\n투표 전에 이번 Day의 두 용의자 모델을 제출하세요. 가설의 정답은 사건 종료 전까지 공개되지 않습니다.")

    var panel = TheoryPanelScript.new()
    panel.configure(deduction)
    panel.theory_submitted.connect(_on_theory_submitted)
    action_box.add_child(panel)
    _add_action("Investigator Notebook 열기", c_panel, _open_notebook, "가설 제출 전에 증거 연결을 다시 검토")

    if deduction.theory_ready_for_vote():
        _add_info("THEORY LOCKED FOR DAY %d · %s" % [deduction.day, deduction.theory_summary()])
        _add_info("이제 한 명을 격리 투표할 수 있습니다. 이 투표와 두 명 용의자 가설은 별개의 기록으로 남습니다.")
        for npc_id in deduction.crew_order:
            var npc = deduction.npcs[npc_id]
            if not npc.alive:
                continue
            _add_action("%s · %s 격리" % [str(npc.display_name), str(npc.job)], c_red, _vote.bind(npc_id), "이번 Day의 격리표")

func _on_theory_submitted(message: String) -> void:
    if feedback_fx != null:
        feedback_fx.play("evidence")
        feedback_fx.flash(c_gold, 0.12)
    log_event_to_ui(message)
    _refresh_actions()

func _show_personal_event(hypothesis) -> void:
    var deduction = _deduction_game()
    if deduction == null:
        super._show_personal_event(hypothesis)
        return
    for child in action_box.get_children():
        child.queue_free()
    var event: Dictionary = deduction.pending_personal_event
    var npc_id: String = str(event.get("npc_id", ""))
    var npc_name: String = npc_id
    if npc_id in deduction.npcs:
        npc_name = str(deduction.npcs[npc_id].display_name)
        deduction.selected_npc_id = npc_id
        _show_selected_profile()
    detail_box.append_text("\n\n[font_size=14][color=#8ea5c5]PRIVATE SCENE[/color][/font_size]\n[color=#aebbd0]%s[/color]\n\n[font_size=24][color=#ff9ed1]%s[/color][/font_size]\n%s" % [str(event.get("scene_beat", "")), str(event.get("title", "PRIVATE CHANNEL")), str(event.get("prompt", ""))])
    var choices: Array = event.get("choices", [])
    for i in range(choices.size()):
        var choice: Dictionary = choices[i]
        var accent: Color = c_green if i == 0 else c_gold if i == 2 else c_panel
        _add_action(str(choice.get("label", "선택")), accent, _resolve_personal_event.bind(i), "%s와의 신뢰·스트레스에 제한적으로 영향" % npc_name)

func _vote(npc_id: String) -> void:
    var deduction = _deduction_game()
    if deduction != null and not deduction.theory_ready_for_vote():
        if feedback_fx != null:
            feedback_fx.play("alert")
            feedback_fx.flash(c_gold, 0.10)
        log_event_to_ui("CASE THEORY를 먼저 제출해야 합니다.")
        _refresh_actions()
        return
    super._vote(npc_id)

func _record_theory_meta_if_needed(deduction) -> void:
    if not deduction.game_over or deduction.final_theory_result.is_empty():
        return
    var key: String = "%d:%s" % [deduction.seed_value, deduction.case_id]
    if key == _theory_meta_recorded_key:
        return
    _theory_meta_recorded_key = key
    meta_progress.record_theory_result(deduction.final_theory_result)

func _refresh() -> void:
    super._refresh()
    var deduction = _deduction_game()
    if deduction == null:
        return
    if phase_label != null:
        var theory_tag: String = "THEORY ✓" if deduction.theory_ready_for_vote() else "THEORY —"
        phase_label.text = "DAY %d · %s · %s · %s" % [deduction.day, deduction.phase_display_name(), deduction.case_subtitle, theory_tag]
