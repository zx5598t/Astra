extends "res://scripts/main_v005.gd"

var notebook_open: bool = false
var session_case_history: Array[String] = []
var session_insight: int = 0
var _preferred_case: String = ""
var _recorded_result_key: String = ""
var _meeting_ai_day: int = -1
var _meeting_ai_queue: Array[Dictionary] = []
var _meeting_ai_inflight: bool = false

func _replace_version_label(node: Node) -> void:
    if node is Label:
        var label := node as Label
        if label.text.begins_with("0.0.3") or label.text.begins_with("0.0.4") or label.text.begins_with("0.0.5"):
            label.text = "0.0.6 · Random Cases · Investigator Notebook · AI Meeting Performance"
        elif label.text == "INCIDENT ZERO":
            label.text = "CASE SHUFFLE PROTOCOL"
        elif label.text == "DEAD AIR":
            label.text = "Two incidents · Two hidden Nulls · Every run changes"
    for child in node.get_children():
        _replace_version_label(child)

func _start_game() -> void:
    _launch_case(_preferred_case)
    _preferred_case = ""

func _launch_case(preferred: String = "") -> void:
    notebook_open = false
    _meeting_ai_day = -1
    _meeting_ai_queue.clear()
    _meeting_ai_inflight = false
    game = AstraRandomCaseGameState.new()
    var random_game := game as AstraRandomCaseGameState
    random_game.preferred_case_id = preferred
    game.state_changed.connect(_refresh)
    var seed := int(Time.get_unix_time_from_system()) % 1000000
    game.setup(seed)
    _build_game_ui()
    _install_ai_client_v006()
    _refresh()

func _install_ai_client_v006() -> void:
    if ai_client != null and is_instance_valid(ai_client):
        ai_client.queue_free()
    ai_client = RemoteAIClientScript.new()
    ai_client.endpoint = game.ai_gateway.endpoint
    add_child(ai_client)
    ai_client.action_received.connect(_on_ai_action_received)
    ai_status = "AI BACKEND PATH · %s" % ai_client.endpoint

func _random_game() -> AstraRandomCaseGameState:
    return game as AstraRandomCaseGameState

func _refresh_actions() -> void:
    var random_game := _random_game()
    if random_game == null:
        super._refresh_actions()
        return

    if notebook_open:
        for child in action_box.get_children():
            child.queue_free()
        detail_box.text = random_game.notebook_report_bbcode()
        _add_action("← 사건 화면으로 돌아가기", c_cyan, _close_notebook, "현재 phase로 복귀")
        return

    if random_game.phase_name() == "BRIEFING" and random_game.day == 1:
        for child in action_box.get_children():
            child.queue_free()
        detail_box.text = "[color=#55d6ff][font_size=28]%s[/font_size][/color]\n[color=#8ea5c5]%s[/color]\n\n%s\n\n[b]MISSION[/b] · %s\n\n[color=#ffd36a]승무원 8명 · Null 2명 · 역할은 이번 Seed에서 무작위 배정[/color]" % [random_game.case_title, random_game.case_subtitle, random_game.case_theme, str(random_game.truth.incident.get("objective", ""))]
        _add_info("이번 판의 Null 신분과 핵심 증거 대상은 이전 판과 달라질 수 있습니다.")
        _add_action("Investigator Notebook 열기", c_panel, _open_notebook, "발견한 증거와 발언만 연결해 표시")
        return

    super._refresh_actions()

    if random_game.phase_name() != "RESULT":
        _add_action("Investigator Notebook", c_panel, _open_notebook, "증거 → 인물 → 알리바이 모순 후보 확인")

    if random_game.phase_name() == "MEETING":
        _queue_meeting_ai_if_needed()

    if random_game.phase_name() == "RESULT":
        _record_result_if_needed()
        _add_info("SESSION INSIGHT · %d   /   완료 사건 %d" % [session_insight, session_case_history.size()])
        _add_action("다음 사건으로 →", c_green, _start_next_case, "다른 사건 템플릿으로 이어서 플레이")
        _add_action("Investigator Notebook 최종 기록", c_panel, _open_notebook, "이번 사건의 증거와 모순 기록 확인")

func _open_notebook() -> void:
    notebook_open = true
    _refresh_actions()

func _close_notebook() -> void:
    notebook_open = false
    _refresh_actions()

func _record_result_if_needed() -> void:
    var random_game := _random_game()
    if random_game == null or not random_game.game_over:
        return
    var key := "%d:%s" % [random_game.seed_value, random_game.case_id]
    if key == _recorded_result_key:
        return
    _recorded_result_key = key
    session_case_history.append(random_game.case_id)
    session_insight += random_game.discovered_evidence.size()
    session_insight += random_game.contradiction_register.size() * 2
    var correct := 0
    for item in random_game.day_vote_history:
        if str(item.get("role", "")) == "NULL":
            correct += 1
    session_insight += correct * 4

func _start_next_case() -> void:
    var random_game := _random_game()
    if random_game == null:
        _start_game()
        return
    _preferred_case = random_game.next_case_id()
    _launch_case(_preferred_case)
    _preferred_case = ""

func _queue_meeting_ai_if_needed() -> void:
    var random_game := _random_game()
    if random_game == null or ai_client == null or not game.ai_gateway.is_available():
        return
    if _meeting_ai_day == random_game.day:
        return
    _meeting_ai_day = random_game.day
    _meeting_ai_queue.clear()
    var max_events := mini(3, random_game.meeting_events.size())
    for i in range(max_events):
        var event: Dictionary = random_game.meeting_events[i]
        var speaker_id := str(event.get("speaker", ""))
        if speaker_id == "" or speaker_id not in random_game.npcs or not random_game.npcs[speaker_id].alive:
            continue
        _meeting_ai_queue.append({"event_index":i, "speaker_id":speaker_id})
    _send_next_meeting_ai()

func _send_next_meeting_ai() -> void:
    if _meeting_ai_inflight or _meeting_ai_queue.is_empty() or ai_client == null or ai_client.busy:
        return
    var random_game := _random_game()
    if random_game == null:
        return
    var item: Dictionary = _meeting_ai_queue.pop_front()
    var event_index := int(item.get("event_index", -1))
    var speaker_id := str(item.get("speaker_id", ""))
    if event_index < 0 or event_index >= random_game.meeting_events.size():
        _send_next_meeting_ai()
        return
    var event: Dictionary = random_game.meeting_events[event_index]
    var context := random_game.build_ai_context(speaker_id, "public_meeting", str(event.get("kind", "claim")))
    if not context.has("scene"):
        context["scene"] = {}
    context["scene"]["target_id"] = str(event.get("target", ""))
    context["scene"]["rule_based_line"] = str(event.get("text", ""))
    _request_serial += 1
    var request_id := "meeting-%d-%d-%s" % [random_game.day, _request_serial, speaker_id]
    _pending_ai[request_id] = {"kind":"meeting", "event_index":event_index, "npc_id":speaker_id, "context":context}
    var payload := game.ai_gateway.build_request_payload(context)
    if ai_client.request_action(payload, request_id):
        _meeting_ai_inflight = true
        ai_status = "AI MEETING…"
    else:
        _pending_ai.erase(request_id)
        _meeting_ai_inflight = false

func _on_ai_action_received(request_id: String, action: Dictionary, success: bool, error_message: String) -> void:
    if request_id in _pending_ai:
        var pending: Dictionary = _pending_ai[request_id]
        if str(pending.get("kind", "")) == "meeting":
            _pending_ai.erase(request_id)
            _meeting_ai_inflight = false
            var random_game := _random_game()
            if random_game != null:
                var context: Dictionary = pending.get("context", {})
                var allowed_refs: Array[String] = []
                for ref in context.get("allowed_fact_refs", []):
                    allowed_refs.append(str(ref))
                var allowed_targets: Array[String] = []
                for target_id in context.get("allowed_target_ids", []):
                    allowed_targets.append(str(target_id))
                if success and game.ai_gateway.validate_action(action, allowed_refs, allowed_targets):
                    random_game.apply_meeting_ai(int(pending.get("event_index", -1)), action)
                    ai_status = "AI MEETING VALIDATED"
                    _refresh_actions()
                    _refresh_npcs()
                elif error_message != "":
                    ai_status = "OFFLINE FALLBACK"
                    log_event_to_ui("AI meeting fallback · %s" % error_message)
            _send_next_meeting_ai()
            return
    super._on_ai_action_received(request_id, action, success, error_message)

func _refresh() -> void:
    super._refresh()
    var random_game := _random_game()
    if random_game == null:
        return
    if phase_label != null:
        phase_label.text = "DAY %d · %s · %s" % [random_game.day, random_game.phase_display_name(), random_game.case_subtitle]
    if random_game.game_over:
        _record_result_if_needed()
