extends SceneTree

# Scripted narrative walkthrough (§95): Stage 1 → 2 → 3 → 4 → PART II → Stage 5
# Day 2+, played like a person would (talk to the tagged people, follow up,
# step in once in the meeting, vote), with one deliberately wrong vote on
# Stage 2 Day 1. Every line a player would read is written to
# build/qa/walkthrough_080.txt so a human can read the run top to bottom.
#   godot --headless --path . --script res://tests/walkthrough_080.gd

var out: Array = []
var explorer_id := "neutral"

func _initialize() -> void:
    var seeds := {"CALIBRATION": 4242, "DEAD_AIR": 5151, "GLASS_GARDEN": 6161, "ECHO_WARD": 7171, "SILENT_ORBIT": 8181}
    for case_id in ["CALIBRATION", "DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD", "SILENT_ORBIT"]:
        _play(case_id, int(seeds[case_id]), "GUARDIAN" if case_id == "SILENT_ORBIT" else "NONE", case_id == "DEAD_AIR")
    for id in ["serin", "mika"]:
        explorer_id = id
        for case_id in ["CALIBRATION", "DEAD_AIR", "GLASS_GARDEN", "SILENT_ORBIT"]:
            _play(case_id, int(seeds[case_id]), "GUARDIAN" if case_id == "SILENT_ORBIT" else "NONE", false)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/walkthrough_080.txt", FileAccess.WRITE)
    file.store_string("\n".join(PackedStringArray(out)))
    file.close()
    # Anything a player reads must be fully formatted.
    var bad: Array = []
    for line in out:
        var text := str(line)
        if text.contains("[표시]"):
            continue
        if text.contains("{") or text.contains("}") or text.contains("|i") or text.contains("|eun"):
            bad.append(text)
    if not bad.is_empty():
        for text in bad:
            print("UNFORMATTED: " + text)
        print("ASTRA WALKTHROUGH 080 FAILED · %d unformatted lines" % bad.size())
        quit(1)
        return
    print("ASTRA WALKTHROUGH 080 OK · %d lines" % out.size())
    quit()

func w(text: String) -> void:
    out.append(text)

func _name(s: AstraGameSession, id: String) -> String:
    if id == "player":
        return "당신"
    if id == "" or id == "narration":
        return "—"
    return s.name_of(id)

func _read_story(s: AstraGameSession) -> void:
    var guard := 0
    while not s.story_finished() and guard < 200:
        guard += 1
        var scene := s.story_scene()
        var lines: Array = scene.get("lines", [])
        var index := s.story_line_index()
        if index == 0 and str(scene.get("action", "")) != "" and not bool(scene.get("action_only", false)):
            w("   (%s)" % str(scene.get("action", "")))
        if index < lines.size():
            w("   %s: %s" % [_name(s, str(lines[index][0])), str(lines[index][1])])
        var choices: Array = scene.get("choices", [])
        if not choices.is_empty() and index >= lines.size() - 1:
            var labels: Array = []
            for c in choices:
                labels.append(str(c.get("label", "")))
            w("   [선택지] " + " / ".join(PackedStringArray(labels)) + "  → 첫 번째 선택")
            s.story_choose(0)
        else:
            s.story_next()

func _play(case_id: String, seed_value: int, protocol: String, wrong_first: bool) -> void:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value, protocol)
    if explorer_id in AstraExplorerCatalog.ORDER:
        s.set_player_profile(AstraExplorerCatalog.profile_for(explorer_id))
    w("탐사요원: %s · seed %d" % [s.player_profile()["name"], seed_value])
    w("")
    w("==================== %s · STAGE %d · %s ====================" % [AstraCaseCatalog.part_label(case_id), s.stage_index(), str(AstraVoyageContent.chapter(case_id).get("title", ""))])
    var guard := 0
    while s.phase != "RESULT" and guard < 60:
        guard += 1
        match s.phase:
            "BRIEFING":
                w("")
                w("---- DAY %d 아침 ----" % s.day)
                _read_story(s)
                s.advance()
            "INTERROGATION":
                w("")
                w("---- DAY %d 대화 (%d번) · 오늘의 질문: %s ----" % [s.day, s.conversations_max(), s.day_question()])
                var leads := s.talk_leads()
                w("   [표시] " + str(leads))
                var order: Array = leads.keys() + s.living_ids()
                var talked: Array = []
                for id in order:
                    if s.conversations_left() <= 0:
                        break
                    if str(id) in talked or not s.is_alive(str(id)):
                        continue
                    talked.append(str(id))
                    var r := s.ask(str(id), "STATEMENT")
                    for line in r.get("lines", []):
                        w("   %s: %s" % [_name(s, str(line.get("speaker", ""))), str(line.get("text", ""))])
                    var g2 := 0
                    while s.followups_left(str(id)) > 0 and g2 < 3:
                        g2 += 1
                        var options := s.question_options(str(id))
                        if options.is_empty():
                            break
                        var labels: Array = []
                        for o in options:
                            labels.append(str(o.get("label", "")))
                        w("   [선택지] " + " / ".join(PackedStringArray(labels)))
                        var pick: Dictionary = options[0]
                        var rr := s.ask(str(id), str(pick["intent"]), str(pick.get("ref", "")))
                        for line in rr.get("lines", []):
                            w("   %s: %s" % [_name(s, str(line.get("speaker", ""))), str(line.get("text", ""))])
                        if rr.has("reaction"):
                            w("   (%s)" % str(rr["reaction"].get("text", "")))
                s.advance()
            "MEETING":
                w("")
                w("---- DAY %d 회의 (%s) ----" % [s.day, s.meeting_temperature()])
                var shown := 0
                var intervened := false
                var g3 := 0
                while not s.meeting_over() and g3 < 10:
                    g3 += 1
                    for i in range(shown, s.meeting_feed.size()):
                        var e: Dictionary = s.meeting_feed[i]
                        w("   %s: %s" % [_name(s, str(e.get("speaker", ""))), str(e.get("text", ""))])
                    shown = s.meeting_feed.size()
                    if explorer_id != "neutral":
                        var checks := s.clarification_options()
                        if not checks.is_empty():
                            w("   >> 재확인: " + str(checks[0]["label"]))
                            var checked := s.intervene("clarify", str(checks[0]["ref"]))
                            for line in checked.get("lines", []):
                                w("   %s: %s" % [_name(s, str(line.get("speaker", ""))), str(line.get("text", ""))])
                            shown = s.meeting_feed.size()
                    var options := s.meeting_options()
                    if not options.is_empty():
                        var labels: Array = []
                        for o in options:
                            labels.append(str(o.get("label", "")))
                        w("   [개입 선택지] " + " / ".join(PackedStringArray(labels)))
                    if not intervened:
                        var pick := AstraTestBots._smart_moment_pick(s)
                        if not pick.is_empty():
                            w("   >> 개입: " + str(pick.get("label", "")))
                            s.intervene(str(pick["kind"]), str(pick["ref"]))
                            intervened = true
                            for i in range(shown, s.meeting_feed.size()):
                                var e2: Dictionary = s.meeting_feed[i]
                                w("   %s: %s" % [_name(s, str(e2.get("speaker", ""))), str(e2.get("text", ""))])
                            shown = s.meeting_feed.size()
                    s.meeting_continue()
                for i in range(shown, s.meeting_feed.size()):
                    var e3: Dictionary = s.meeting_feed[i]
                    w("   %s: %s" % [_name(s, str(e3.get("speaker", ""))), str(e3.get("text", ""))])
                var responses := 0
                var repeats := 0
                var previous := ""
                for line in s.meeting_feed:
                    responses += 1 if str(line.get("thread_role", "")) in ["response", "challenge"] else 0
                    repeats += 1 if str(line.get("text", "")) == previous else 0
                    previous = str(line.get("text", ""))
                w("   [QA] arcs=%d responses/challenges=%d immediate_repeats=%d checks_used=%d" % [s.stage_state().get("meeting_arcs", []).size(), responses, repeats, 3-int(s.stage_state().get("clarifications_left", 3))])
                s.advance()
            "VOTE":
                w("")
                w("---- DAY %d 투표 ----" % s.day)
                for st in s.final_statements():
                    w("   [마지막 한마디] %s: %s" % [str(st.get("name", "")), str(st.get("text", ""))])
                var target := AstraTestBots._player_top(s)
                if wrong_first and s.day == 1:
                    for id in s.eligible_vote_targets():
                        if str(id) not in s.living_null_ids():
                            target = str(id)
                            break
                    w("   (일부러 틀린 선택: %s)" % s.name_of(target))
                AstraTestBots._vote(s, target)
                for b in s.vote_ballots():
                    w("   %s → %s  %s" % [_name(s, str(b.get("voter", ""))), s.name_of(str(b.get("target", ""))), str(b.get("line", ""))])
                w("   결과: " + s.vote_result_text())
                for beat in s.last_vote.get("aftermath", []):
                    w("   [격리 장면] %s%s" % [(_name(s, str(beat.get("speaker", ""))) + ": ") if str(beat.get("kind", "")) in ["target", "observer"] else "", str(beat.get("text", ""))])
                s.advance()
            "NIGHT":
                var options: Array = s.night_options().get("protect", [])
                var pick := "player" if "player" in options else (str(options[0]) if not options.is_empty() else "")
                w("")
                w("---- DAY %d 밤 · Aegis → %s ----" % [s.day, _name(s, pick)])
                if pick != "":
                    s.choose_night_action("protect", pick)
                else:
                    s.choose_night_action("skip", "")
                s.advance()
    w("")
    w("---- 결과: %s (%s) ----" % [str(s.final_report.get("title", "")), str(s.final_report.get("subtitle", ""))])
    _read_story(s)
    for line in Dictionary(s.final_report.get("loop_summary", {})).get("lines", []):
        w("   · " + str(line))
