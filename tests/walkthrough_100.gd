extends SceneTree

# 1.0 human-readable dump: build/qa/walkthrough_100.txt
#   godot --headless --path . --script res://tests/walkthrough_100.gd
# Stages 1, 2, 3, 4, 5, 9 and 13 played by a thinking explorer (talks, follows
# up, links statements to evidence, asks clarifying questions, gives a reason
# for each ballot), everything the player would read written out: morning,
# conversations, meeting (with links and the room's answers), closing, final
# words, ballots with reasons, result. Then Stage 3 on one seed with Serin,
# Mika and Logan: same truth, different people.

var out: PackedStringArray = []

func w(line: String) -> void:
    out.append(line)

func _initialize() -> void:
    var plan := [["CALIBRATION", 4242, "serin"], ["DEAD_AIR", 5151, "rael"], ["GLASS_GARDEN", 6161, "serin"],
        ["ECHO_WARD", 7171, "mika"], ["SILENT_ORBIT", 8181, "jace"], ["BORROWED_DAYS", 9191, "sia"], ["THRESHOLD", 1313, "logan"]]
    for entry in plan:
        _play(str(entry[0]), int(entry[1]), str(entry[2]))
    w("")
    w("################ 같은 Stage, 같은 seed, 다른 탐사요원 ################")
    var truths := {}
    for id in ["serin", "mika", "logan"]:
        var s := _play("GLASS_GARDEN", 7777, id, 1)
        truths[JSON.stringify(s.truth)] = true
    w("진실 동일: %s" % ("예" if truths.size() == 1 else "아니오"))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/walkthrough_100.txt", FileAccess.WRITE)
    file.store_string("\n".join(out))
    file.close()
    print("ASTRA WALKTHROUGH 100 OK · %d lines" % out.size())
    quit()

func _name(s: AstraGameSession, id: String) -> String:
    if id == "player":
        return "당신(%s)" % str(s.player_profile().get("name", ""))
    if id == "":
        return "·"
    return s.name_of(id)

func _play(case_id: String, seed: int, explorer: String, max_days: int = 6) -> AstraGameSession:
    var s := AstraGameSession.new()
    var stage := AstraCaseCatalog.stage_index(case_id)
    s.setup(case_id, seed, "GUARDIAN" if stage >= 5 else "NONE")
    s.set_player_profile(AstraExplorerCatalog.profile_for(explorer))
    w("")
    w("==================== STAGE %d · %s · 탐사요원 %s · seed %d ====================" % [stage, str(AstraVoyageContent.chapter(case_id).get("title", case_id)), s.player_profile()["name"], seed])
    var guard := 0
    while s.phase != "RESULT" and guard < 200 and s.day <= max_days:
        guard += 1
        match s.phase:
            "BRIEFING":
                w("")
                w("---- DAY %d 아침 ----" % s.day)
                var g2 := 0
                while not s.story_finished() and g2 < 200:
                    g2 += 1
                    var scene := s.story_scene()
                    var lines: Array = scene.get("lines", [])
                    var index := s.story_line_index()
                    if index < lines.size():
                        w("  %s: %s" % [_name(s, str(lines[index][0])), s._fill_story(str(lines[index][1]))])
                    if str(scene.get("kind", "")) == "interlude":
                        s.finish_interlude(str(scene.get("interlude", "")), "success")
                    elif not Array(scene.get("choices", [])).is_empty() and index >= lines.size() - 1:
                        s.story_choose(0)
                    else:
                        s.story_next()
                s.advance()
            "INTERROGATION":
                w("---- DAY %d 대화 · 오늘의 질문: %s ----" % [s.day, s.day_question()])
                var order: Array = s.living_ids().duplicate()
                var leads := s.talk_leads()
                order.sort_custom(func(a, b): return (1.0 if leads.has(str(a)) else 0.0) + s.suspicion_score("player", str(a)) > (1.0 if leads.has(str(b)) else 0.0) + s.suspicion_score("player", str(b)))
                for npc_id in order:
                    if s.conversations_left() <= 0:
                        break
                    var r := s.ask(str(npc_id), "STATEMENT")
                    for line in r.get("lines", []):
                        w("  %s: %s" % [_name(s, str(line.get("speaker", ""))), str(line.get("text", ""))])
                    var g3 := 0
                    while s.followups_left(str(npc_id)) > 0 and g3 < 3:
                        g3 += 1
                        var picked := {}
                        for option in s.question_options(str(npc_id)):
                            if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["CONFRONT", "RECORD", "WITNESS", "REASSURE"]:
                                picked = option
                                break
                        if picked.is_empty():
                            break
                        w("  >> 질문: %s" % str(picked.get("label", "")))
                        var r2 := s.ask(str(npc_id), str(picked["intent"]), str(picked.get("ref", "")))
                        for line in r2.get("lines", []):
                            w("  %s: %s" % [_name(s, str(line.get("speaker", ""))), str(line.get("text", ""))])
                    w("")
                s.advance()
            "MEETING":
                w("---- DAY %d 회의 ----" % s.day)
                var shown := 0
                var g4 := 0
                while not s.meeting_over() and g4 < 12:
                    g4 += 1
                    for i in range(shown, s.meeting_feed.size()):
                        var e: Dictionary = s.meeting_feed[i]
                        w("  %s: %s" % [_name(s, str(e.get("speaker", ""))), str(e.get("text", ""))])
                    shown = s.meeting_feed.size()
                    var soft := s.clarification_options()
                    if not soft.is_empty() and g4 % 2 == 1:
                        w("  >> 확인 질문: %s" % str(soft[0]["label"]))
                        s.intervene("clarify", str(soft[0]["ref"]))
                    var link := AstraTestBots.smart_link(s)
                    if link != "" and s.meeting_actions_left > 0:
                        var parts := link.split("|")
                        w("  >> 연결: %s ↔ %s%s" % [parts[0], parts[1], (" + " + parts[2]) if parts.size() > 2 else ""])
                        s.intervene("link", link)
                        var last: Dictionary = s.stage_state().get("links", []).back()
                        w("     판정: %s — %s" % [str(last.get("result", "")), str(last.get("why", ""))])
                    for i in range(shown, s.meeting_feed.size()):
                        var e2: Dictionary = s.meeting_feed[i]
                        w("  %s: %s" % [_name(s, str(e2.get("speaker", ""))), str(e2.get("text", ""))])
                    shown = s.meeting_feed.size()
                    s.meeting_continue()
                for i in range(shown, s.meeting_feed.size()):
                    var e3: Dictionary = s.meeting_feed[i]
                    w("  %s: %s" % [_name(s, str(e3.get("speaker", ""))), str(e3.get("text", ""))])
                s.advance()
            "VOTE":
                w("---- DAY %d 투표 ----" % s.day)
                for statement in s.final_statements():
                    w("  마지막 말 · %s: %s" % [str(statement.get("name", "")), str(statement.get("text", ""))])
                var target := AstraTestBots._player_top(s)
                var reasons := s.ballot_reasons(target)
                s.set_ballot_reason(target, 0)
                w("  당신의 표: %s · 이유: %s" % [s.name_of(target), str(reasons[0]["text"])])
                AstraTestBots._vote(s, target)
                for ballot in s.vote_ballots():
                    if str(ballot.get("voter", "")) != "player":
                        w("  %s → %s  “%s”" % [s.name_of(str(ballot.get("voter", ""))), s.name_of(str(ballot.get("target", ""))), str(ballot.get("line", ""))])
                var iso := str(s.last_vote.get("isolated", ""))
                w("  격리: %s (%s)" % [s.name_of(iso), "Null" if iso in Array(s.truth.get("nulls", [])) else "무고"])
                s.advance()
            "NIGHT":
                AstraTestBots._night(s, true)
                s.advance()
                w("---- 밤 · %s ----" % str(s.night_result.get("text", s.night_result.get("victim", ""))))
    w("결과: %s / %s · Null %s" % [str(s.outcome), s.outcome_reason(), s.names_of(s.truth.get("nulls", []))])
    return s
