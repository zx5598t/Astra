extends "res://scripts/main_v007.gd"

const HypothesisStateScript = preload("res://scripts/hypothesis_game_state.gd")
const InteractiveBoardScript = preload("res://scripts/interactive_notebook_board.gd")
const FeedbackFXScript = preload("res://scripts/feedback_fx.gd")
const TheoryModelScript = preload("res://scripts/case_theory_model.gd")
const TheoryPanelScript = preload("res://scripts/case_theory_panel.gd")
const IncidentStageScript = preload("res://scripts/incident_stage.gd")

var feedback_fx
var _last_personal_result: String = ""
var theory_model
var _theory_meta_recorded_key: String = ""
var _theory_score_applied_key: String = ""

func _replace_version_label(node: Node) -> void:
    if node is Label:
        var label := node as Label
        if label.text.begins_with("0.0.3") or label.text.begins_with("0.0.4") or label.text.begins_with("0.0.5") or label.text.begins_with("0.0.6") or label.text.begins_with("0.0.7") or label.text.begins_with("0.0.8"):
            label.text = "0.0.9 · Case Theory Review · Cinematic Incident Stage · Expanded Private Events · %s" % meta_progress.archive_rank()
        elif label.text == "ASTRA ARCHIVE" or label.text == "ASTRA // OBSERVER ARCHIVE":
            label.text = "ASTRA // CASE ANALYSIS"
        elif label.text.begins_with("Two incidents") or label.text == "DEAD AIR":
            label.text = meta_progress.summary()
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
    _theory_score_applied_key = ""
    _last_personal_result = ""
    game = HypothesisStateScript.new()
    game.preferred_case_id = preferred
    theory_model = TheoryModelScript.new()
    theory_model.reset()
    game.state_changed.connect(_refresh)
    var seed := int(Time.get_unix_time_from_system()) % 1000000
    game.setup(seed)
    _build_game_ui()
    _install_ai_client_v006()
    _install_feedback_fx()
    _refresh()
    if feedback_fx != null:
        feedback_fx.flash(c_cyan, 0.10)

func _install_feedback_fx() -> void:
    if feedback_fx != null and is_instance_valid(feedback_fx):
        feedback_fx.queue_free()
    feedback_fx = FeedbackFXScript.new()
    add_child(feedback_fx)

func _hypothesis_game():
    return game

func _refresh_actions() -> void:
    var hypothesis = _hypothesis_game()
    if hypothesis == null:
        super._refresh_actions()
        return

    if notebook_open:
        for child in action_box.get_children():
            child.queue_free()
        detail_box.text = "[font_size=27][color=#55d6ff]PLAYER HYPOTHESIS BOARD[/color][/font_size]\n[color=#8ea5c5]%s · Day %d · Evidence %d/8 · Your links %d[/color]\n\n[color=#ffd36a]왼쪽 증거를 고른 뒤 오른쪽 Crew를 클릭해 직접 가설을 만드세요.[/color]" % [hypothesis.case_subtitle, hypothesis.day, hypothesis.discovered_evidence.size(), hypothesis.manual_links.size()]
        var board := InteractiveBoardScript.new()
        board.configure(hypothesis)
        board.hypothesis_changed.connect(_on_hypothesis_changed)
        action_box.add_child(board)
        _add_action("← 사건 화면으로 돌아가기", c_cyan, _close_notebook, "가설 연결은 이번 사건 동안 유지")
        return

    if not hypothesis.pending_personal_event.is_empty():
        _show_personal_event_v009(hypothesis)
        return

    if hypothesis.phase_name() == "VOTE":
        _show_theory_vote_gate(hypothesis)
        return

    super._refresh_actions()

    if _last_personal_result != "":
        detail_box.append_text("\n\n[font_size=18][color=#ff9ed1]PRIVATE CHANNEL RESULT[/color][/font_size]\n%s" % _last_personal_result)
        _last_personal_result = ""

    if hypothesis.phase_name() == "BRIEFING" and hypothesis.day == 1:
        _install_incident_stage(hypothesis)

    if hypothesis.phase_name() == "RESULT":
        _finalize_theory_if_needed(hypothesis)
        var review: String = ""
        if theory_model != null:
            review = str(theory_model.final_theory_bbcode(hypothesis))
        if review != "":
            detail_box.append_text("\n\n" + review)
        _record_theory_meta_if_needed(hypothesis)
        _add_info("DEDUCTION ARCHIVE · theories %d · perfect %d · best %d" % [meta_progress.theories_submitted, meta_progress.perfect_theories, meta_progress.best_theory_score])

func _install_incident_stage(hypothesis) -> void:
    var stage := IncidentStageScript.new()
    stage.configure(hypothesis)
    action_box.add_child(stage)
    action_box.move_child(stage, 0)

func _show_theory_vote_gate(hypothesis) -> void:
    for child in action_box.get_children():
        child.queue_free()
    _show_selected_profile()
    detail_box.append_text("\n\n[font_size=24][color=#ffd36a]CASE THEORY GATE[/color][/font_size]\n투표 전에 이번 Day의 두 용의자 모델을 제출하세요. 정답 여부는 사건 종료 전까지 공개되지 않습니다.")

    var panel := TheoryPanelScript.new()
    panel.configure(hypothesis, theory_model)
    panel.theory_submitted.connect(_on_theory_submitted)
    action_box.add_child(panel)

    _add_action("Investigator Notebook 열기", c_panel, _open_notebook, "가설 제출 전에 증거 연결을 다시 검토")

    if theory_model != null and theory_model.theory_ready_for_vote(int(hypothesis.day)):
        _add_info("THEORY LOCKED FOR DAY %d · %s" % [hypothesis.day, theory_model.theory_summary(hypothesis)])
        _add_info("이제 한 명을 격리 투표할 수 있습니다. 격리표와 두 명 용의자 가설은 별개의 기록으로 남습니다.")
        for npc_id in hypothesis.crew_order:
            var npc = hypothesis.npcs[npc_id]
            if not npc.alive:
                continue
            _add_action("%s · %s 격리" % [str(npc.display_name), str(npc.job)], c_red, _vote.bind(npc_id), "이번 Day의 격리표")

func _on_theory_submitted(message: String) -> void:
    if feedback_fx != null:
        feedback_fx.play("evidence")
        feedback_fx.flash(c_gold, 0.12)
    if detail_box != null:
        detail_box.append_text("\n\n[color=#5ee3a0]%s[/color]" % message)
    _refresh_actions()

func _show_personal_event_v009(hypothesis) -> void:
    for child in action_box.get_children():
        child.queue_free()
    var event: Dictionary = hypothesis.pending_personal_event
    var npc_id := str(event.get("npc_id", ""))
    var npc_name := npc_id
    if npc_id in hypothesis.npcs:
        npc_name = str(hypothesis.npcs[npc_id].display_name)
        hypothesis.selected_npc_id = npc_id
        _show_selected_profile()
    detail_box.append_text("\n\n[font_size=14][color=#8ea5c5]PRIVATE SCENE[/color][/font_size]\n[color=#aebbd0]%s[/color]\n\n[font_size=24][color=#ff9ed1]%s[/color][/font_size]\n%s" % [_personal_scene_beat(npc_id), str(event.get("title", "PRIVATE CHANNEL")), str(event.get("prompt", ""))])
    var choices: Array = event.get("choices", [])
    for i in range(choices.size()):
        var choice: Dictionary = choices[i]
        _add_action(str(choice.get("label", "선택")), c_green if i == 0 else c_panel, _resolve_personal_event.bind(i), "%s와의 관계에 제한적으로 영향" % npc_name)
    _add_action("한 사람을 특정하지 말고 관찰 가능한 사실만 다시 말해달라고 한다", c_gold, _resolve_observation_choice, "관계보다 검증 가능한 정보에 집중")

func _resolve_personal_event(choice_index: int) -> void:
    var hypothesis = _hypothesis_game()
    if hypothesis == null:
        return
    var npc_id := str(hypothesis.pending_personal_event.get("npc_id", ""))
    _last_personal_result = hypothesis.resolve_personal_event(choice_index)
    if npc_id != "":
        meta_progress.record_personal_choice(npc_id, choice_index)
    if feedback_fx != null:
        feedback_fx.play("click")
        feedback_fx.flash(Color("ff9ed1"), 0.09)
    _refresh_actions()
    _refresh_npcs()

func _resolve_observation_choice() -> void:
    var hypothesis = _hypothesis_game()
    if hypothesis == null or hypothesis.pending_personal_event.is_empty():
        return
    var event: Dictionary = hypothesis.pending_personal_event
    var npc_id := str(event.get("npc_id", ""))
    var npc_name := npc_id
    if npc_id in hypothesis.npcs:
        var npc = hypothesis.npcs[npc_id]
        npc_name = str(npc.display_name)
        npc.adjust_trust(0.02)
        npc.adjust_stress(-0.01)
    var result_text := "%s은(는) 잠시 감정을 누르고 자신이 직접 본 것과 추측을 구분해서 다시 설명했다." % npc_name
    hypothesis.personal_event_history.append({
        "day":hypothesis.day,
        "case_id":hypothesis.case_id,
        "npc_id":npc_id,
        "choice_index":2,
        "label":"관찰 가능한 사실만 다시 요청",
        "result":result_text
    })
    hypothesis.log_event("PERSONAL CHOICE · %s · observable facts only" % npc_id)
    hypothesis.pending_personal_event.clear()
    hypothesis.score += 10
    _last_personal_result = result_text
    if npc_id != "":
        meta_progress.record_personal_choice(npc_id, 2)
    if feedback_fx != null:
        feedback_fx.play("click")
        feedback_fx.flash(c_gold, 0.09)
    _refresh_actions()
    _refresh_npcs()

func _personal_scene_beat(npc_id: String) -> String:
    match npc_id:
        "mira": return "의료실 비상등이 낮게 깜빡인다. Mira는 장갑을 벗지 않은 채 손끝을 바라본다."
        "rho": return "엔진 진동이 바닥을 울린다. Rho는 렌치를 작업대에 내려놓고 당신을 정면으로 본다."
        "eli": return "항법창 너머 별빛이 천천히 흐른다. Eli는 일부러 화면을 끄고 목소리를 낮춘다."
        "sena": return "보안허브의 감시 화면들이 동시에 당신을 비춘다. Sena는 출입문을 잠근다."
        "vale": return "통신실 스피커에서 백색소음이 흐른다. Vale은 채널 하나를 수동으로 끈다."
        "noa": return "기록보관실의 텍스트 로그가 무수히 스크롤된다. Noa는 한 문장을 멈춰 세운다."
        "lyra": return "수목구역의 습기가 유리벽에 맺힌다. Lyra는 죽은 잎 하나를 조심스럽게 접는다."
        "dax": return "진단 패널의 그래프가 규칙적으로 뛰고 있다. Dax는 수치 하나를 손가락으로 가리킨다."
    return "둘만 남은 짧은 순간, 공개 회의와는 다른 표정이 드러난다."

func _on_hypothesis_changed() -> void:
    meta_progress.record_hypothesis_link()
    if feedback_fx != null:
        feedback_fx.play("click")
        feedback_fx.flash(c_gold, 0.055)

func _investigate(location: String) -> void:
    var hypothesis = _hypothesis_game()
    var before := 0
    if hypothesis != null:
        before = hypothesis.discovered_evidence.size()
    super._investigate(location)
    if hypothesis != null and hypothesis.discovered_evidence.size() > before and feedback_fx != null:
        feedback_fx.play("evidence")
        feedback_fx.flash(c_gold, 0.15)

func _talk(intent: String) -> void:
    if feedback_fx != null:
        feedback_fx.play("click")
    super._talk(intent)

func _advance() -> void:
    if feedback_fx != null:
        feedback_fx.play("click")
        feedback_fx.flash(c_cyan, 0.07)
    super._advance()

func _vote(npc_id: String) -> void:
    var hypothesis = _hypothesis_game()
    if hypothesis != null and (theory_model == null or not theory_model.theory_ready_for_vote(int(hypothesis.day))):
        if feedback_fx != null:
            feedback_fx.play("alert")
            feedback_fx.flash(c_gold, 0.10)
        if detail_box != null:
            detail_box.append_text("\n\n[color=#ffd36a]CASE THEORY를 먼저 제출해야 합니다.[/color]")
        _refresh_actions()
        return
    if feedback_fx != null:
        feedback_fx.play("alert")
        feedback_fx.flash(c_red, 0.18)
        feedback_fx.shake(self, 7.0)
    super._vote(npc_id)

func _finalize_theory_if_needed(hypothesis) -> void:
    if theory_model == null:
        return
    var result: Dictionary = theory_model.finalize(hypothesis)
    var key := "%d:%s" % [hypothesis.seed_value, hypothesis.case_id]
    if key == _theory_score_applied_key:
        return
    _theory_score_applied_key = key
    hypothesis.score += int(result.get("bonus", 0))

func _record_theory_meta_if_needed(hypothesis) -> void:
    if theory_model == null or not hypothesis.game_over or theory_model.final_result.is_empty():
        return
    var key := "%d:%s" % [hypothesis.seed_value, hypothesis.case_id]
    if key == _theory_meta_recorded_key:
        return
    _theory_meta_recorded_key = key
    meta_progress.record_theory_result(theory_model.final_result)

func _refresh() -> void:
    super._refresh()
    var hypothesis = _hypothesis_game()
    if hypothesis == null:
        return
    if phase_label != null:
        var theory_tag := "THEORY —"
        if theory_model != null and theory_model.theory_ready_for_vote(int(hypothesis.day)):
            theory_tag = "THEORY ✓"
        phase_label.text = "DAY %d · %s · %s · %s" % [hypothesis.day, hypothesis.phase_display_name(), hypothesis.case_subtitle, theory_tag]
