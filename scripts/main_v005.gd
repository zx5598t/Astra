extends "res://scripts/main_v004.gd"

const RemoteAIClientScript = preload("res://scripts/remote_ai_client.gd")

var ai_client: AstraRemoteAIClient
var ai_status: String = "OFFLINE FALLBACK"
var _pending_ai: Dictionary = {}
var _request_serial: int = 0

func _replace_version_label(node: Node) -> void:
    if node is Label:
        var label := node as Label
        if label.text.begins_with("0.0.3") or label.text.begins_with("0.0.4"):
            label.text = "0.0.5 · Loop Memory · Optional AI Performance · Offline fallback"
    for child in node.get_children():
        _replace_version_label(child)

func _start_game() -> void:
    game = AstraLoopGameState.new()
    game.state_changed.connect(_refresh)
    var seed := int(Time.get_unix_time_from_system()) % 1000000
    game.setup(seed)
    _build_game_ui()
    _install_ai_client()
    _refresh()

func _install_ai_client() -> void:
    ai_client = RemoteAIClientScript.new()
    ai_client.endpoint = game.ai_gateway.endpoint
    add_child(ai_client)
    ai_client.action_received.connect(_on_ai_action_received)
    ai_status = "AI BACKEND READY PATH · %s" % ai_client.endpoint

func _loop_game() -> AstraLoopGameState:
    return game as AstraLoopGameState

func _refresh_actions() -> void:
    var loop := _loop_game()
    if loop == null:
        super._refresh_actions()
        return
    if loop.phase_name() == "BRIEFING" and loop.day > 1 and loop.day_report_text != "":
        for child in action_box.get_children():
            child.queue_free()
        _show_selected_profile()
        detail_box.append_text("\n\n[font_size=25][color=#55d6ff]DAY %d / %d[/color][/font_size]\n%s\n\n[color=#8ea5c5]전날의 기억·신뢰·마찰이 그대로 유지됩니다.[/color]" % [loop.day, AstraLoopGameState.MAX_DAYS, loop.day_report_text])
        _add_info("다음 단계로 이동하면 남아 있는 증거를 계속 조사합니다.")
        return
    super._refresh_actions()

func _refresh_npcs() -> void:
    var loop := _loop_game()
    if loop == null:
        super._refresh_npcs()
        return
    for child in npc_list.get_children():
        child.queue_free()
    for npc_id in loop.crew_order:
        var npc: NPCState = loop.npcs[npc_id]
        var text := "%s  ·  %s  [%s]" % [npc.display_name, npc.job, npc.concept]
        var b := _button(text, npc.accent)
        if not npc.alive:
            b.text = "×  " + npc.display_name + " · ISOLATED"
            b.disabled = true
        elif loop.selected_npc_id == npc_id:
            b.text = "◆  " + b.text
        var stress := int(float(npc.emotion.get("stress", 0.2)) * 100.0)
        b.tooltip_text = "%s / 신뢰 %d%% · 스트레스 %d%% · 표정 %s" % [npc.vibe, int(npc.trust_player * 100.0), stress, loop.expression_for(npc_id)]
        b.pressed.connect(_select_npc.bind(npc_id))
        npc_list.add_child(b)

func _show_selected_profile() -> void:
    super._show_selected_profile()
    var loop := _loop_game()
    if loop == null or loop.selected_npc_id not in loop.npcs:
        return
    var emotion := loop.expression_for(loop.selected_npc_id)
    portrait_rect.modulate = _emotion_tint(emotion)
    detail_box.append_text("\n[color=#8ea5c5]표정 연출[/color]  %s    [color=#8ea5c5]AI[/color]  %s" % [emotion.to_upper(), ai_status])

func _emotion_tint(emotion: String) -> Color:
    match emotion:
        "warm": return Color(1.0, 0.96, 0.90, 1.0)
        "uneasy": return Color(1.0, 0.92, 0.78, 1.0)
        "angry": return Color(1.0, 0.78, 0.78, 1.0)
        "afraid": return Color(0.84, 0.90, 1.0, 1.0)
        "guarded": return Color(0.88, 0.92, 1.0, 1.0)
        "cold": return Color(0.80, 0.90, 1.0, 1.0)
    return Color.WHITE

func _talk(intent: String) -> void:
    var loop := _loop_game()
    if loop == null:
        super._talk(intent)
        return
    var npc_id := loop.selected_npc_id
    var context := loop.build_ai_context(npc_id, "player_dialogue", intent)
    var response := loop.talk_to(npc_id, intent)
    var npc: NPCState = loop.npcs[npc_id]
    _show_selected_profile()
    detail_box.append_text("\n\n[font_size=22][color=#%s]%s의 답변[/color][/font_size]\n\"%s\"" % [npc.accent.to_html(false), npc.display_name, response])
    _request_ai_performance(npc_id, intent, context, response)

func _request_ai_performance(npc_id: String, intent: String, context: Dictionary, fallback_text: String) -> void:
    if ai_client == null or ai_client.busy or not game.ai_gateway.is_available():
        ai_status = "OFFLINE FALLBACK"
        return
    _request_serial += 1
    var request_id := "%d-%s-%s" % [_request_serial, npc_id, intent]
    var payload := game.ai_gateway.build_request_payload(context)
    _pending_ai[request_id] = {"npc_id":npc_id, "context":context, "fallback":fallback_text}
    if ai_client.request_action(payload, request_id):
        ai_status = "AI THINKING…"
        detail_box.append_text("\n\n[color=#8ea5c5]AI performance 요청 중… 실패하면 위 규칙 기반 대사를 그대로 사용합니다.[/color]")
    else:
        _pending_ai.erase(request_id)
        ai_status = "OFFLINE FALLBACK"

func _on_ai_action_received(request_id: String, action: Dictionary, success: bool, error_message: String) -> void:
    if request_id not in _pending_ai:
        return
    var pending: Dictionary = _pending_ai[request_id]
    _pending_ai.erase(request_id)
    var loop := _loop_game()
    if loop == null:
        return
    var npc_id := str(pending.get("npc_id", ""))
    var context: Dictionary = pending.get("context", {})
    var allowed_refs: Array[String] = []
    for ref in context.get("allowed_fact_refs", []):
        allowed_refs.append(str(ref))
    var allowed_targets: Array[String] = []
    for target_id in context.get("allowed_target_ids", []):
        allowed_targets.append(str(target_id))
    if success and game.ai_gateway.validate_action(action, allowed_refs, allowed_targets):
        loop.apply_ai_performance(npc_id, action)
        ai_status = "AI VALIDATED"
        if loop.selected_npc_id == npc_id:
            _show_selected_profile()
            var npc: NPCState = loop.npcs[npc_id]
            detail_box.append_text("\n\n[font_size=22][color=#%s]%s · AI 연기[/color][/font_size]\n\"%s\"" % [npc.accent.to_html(false), npc.display_name, str(action.get("utterance", ""))])
        log_event_to_ui("AI · %s performance validated" % npc_id)
    else:
        ai_status = "OFFLINE FALLBACK"
        if error_message != "":
            log_event_to_ui("AI fallback · %s" % error_message)
    _refresh_npcs()

func log_event_to_ui(text: String) -> void:
    game.log_event(text)
    _refresh_journal()

func _refresh() -> void:
    super._refresh()
    var loop := _loop_game()
    if loop != null and ap_label != null:
        if loop.phase_name() in ["BRIEFING", "MEETING", "VOTE"]:
            ap_label.text += "   ·   DAY %d/%d   ·   %s" % [loop.day, AstraLoopGameState.MAX_DAYS, ai_status]
