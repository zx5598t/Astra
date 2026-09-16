extends "res://scripts/main.gd"

func _show_title_screen() -> void:
    super._show_title_screen()
    _replace_version_label(self)

func _replace_version_label(node: Node) -> void:
    if node is Label:
        var label := node as Label
        if label.text.begins_with("0.0.3"):
            label.text = "0.0.4 · Social Pressure · Dynamic Dialogue · Offline playable"
    for child in node.get_children():
        _replace_version_label(child)

func _start_game() -> void:
    game = AstraSocialGameState.new()
    game.state_changed.connect(_refresh)
    var seed := int(Time.get_unix_time_from_system()) % 1000000
    game.setup(seed)
    _build_game_ui()
    _refresh()

func _refresh_actions() -> void:
    if game.phase_name() not in ["INTERROGATION", "MEETING"]:
        super._refresh_actions()
        return
    for child in action_box.get_children():
        child.queue_free()
    if game.phase_name() == "INTERROGATION":
        _show_selected_profile()
        for option in game.question_options(game.selected_npc_id):
            var intent := str(option.get("intent", "ALIBI"))
            var accent := c_cyan
            if intent in ["EVIDENCE", "CONTRADICTION"]:
                accent = c_gold
            elif intent in ["CONFIDE", "REASSURE"]:
                accent = c_green
            elif intent == "PRESSURE":
                accent = c_red
            _add_action(str(option.get("label", intent)), accent, _talk.bind(intent), str(option.get("hint", "")))
        return

    _show_selected_profile()
    detail_box.append_text("\n\n[font_size=22][color=#55d6ff]공개 회의 · LIVE[/color][/font_size]\n")
    for event in game.meeting_events:
        var speaker_id := str(event.get("speaker", ""))
        var speaker_name := speaker_id
        if speaker_id in game.npcs:
            speaker_name = game.npcs[speaker_id].display_name
        var kind := str(event.get("kind", "claim"))
        var marker := "발언"
        if kind == "challenge": marker = "반박"
        elif kind == "defend": marker = "끼어들기"
        detail_box.append_text("[color=#8ea5c5][%s][/color] [b]%s[/b] · %s\n\n" % [marker, speaker_name, str(event.get("text", ""))])
    _add_info("관계와 성향에 따라 회의 중 반박과 끼어들기가 발생합니다.")
    var options := game.question_options(game.selected_npc_id)
    var count := mini(3, options.size())
    for i in range(count):
        var option: Dictionary = options[i]
        var intent := str(option.get("intent", "ALIBI"))
        _add_action("공개 질문 · " + str(option.get("label", intent)), c_cyan, _talk.bind(intent), str(option.get("hint", "")))

func _show_selected_profile() -> void:
    super._show_selected_profile()
    var npc: NPCState = game.npcs[game.selected_npc_id]
    var stress := float(npc.emotion.get("stress", 0.2))
    var state := "침착"
    if stress > 0.72: state = "고도로 긴장"
    elif stress > 0.46: state = "경계"
    elif npc.trust_player > 0.68: state = "우호적"
    detail_box.append_text("\n\n[color=#8ea5c5]현재 상태[/color]  %s" % state)
    var social_lines: Array[String] = game.relationship_lines(game.selected_npc_id)
    if not social_lines.is_empty():
        detail_box.append_text("\n[color=#8ea5c5]주요 관계[/color]\n• " + "\n• ".join(social_lines))
