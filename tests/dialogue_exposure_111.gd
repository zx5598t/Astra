extends SceneTree

# ASTRA 1.1.1 HUMAN RHYTHM — runtime-weighted dialogue exposure.
# It records only lines actually reached by representative GameSession play.
const PART_I := ["DEAD_AIR","GLASS_GARDEN","ECHO_WARD"]
const PART_II := ["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]
const CLARIFICATION_NAMES := {
    "time":"TIME", "source":"RECORD", "mates":"COMPANION", "claim":"CLAIM",
    "motive":"MOTIVE", "seen":"WITNESS", "via":"SOURCE"
}

var failures: Array[String] = []
var checks := 0
var transcript: PackedStringArray = []
var exact := {}
var speaker_exact := {}
var openings := {}
var functional := {}
var recent: Array[String] = []
var repeat_in_50 := 0
var clarification_coverage := {}

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    run_exposure()
    if failures.is_empty():
        print("ASTRA DIALOGUE EXPOSURE 111 OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA DIALOGUE EXPOSURE 111 FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

func _normalize(text: String) -> String:
    var value := text.strip_edges().to_lower()
    for token in [" ","\t","\n",".",",","!","?","…","·","“","”","‘","’","(",")",":",";","—","-"]:
        value = value.replace(token, "")
    return value

func _record(case_id: String, day: int, speaker: String, intent: String, source: String, text: String) -> void:
    var clean := text.strip_edges()
    if clean == "":
        return
    var norm := _normalize(clean)
    if norm == "":
        return
    transcript.append("[%s / D%d / %s / %s / %s] %s" % [case_id, day, speaker if speaker != "" else "SYSTEM", intent, source, clean])
    exact[norm] = int(exact.get(norm, 0)) + 1
    speaker_exact[speaker + "|" + norm] = int(speaker_exact.get(speaker + "|" + norm, 0)) + 1
    var opening := norm.left(mini(12, norm.length()))
    if opening.length() >= 10:
        openings[opening] = int(openings.get(opening, 0)) + 1
    var functional_key := intent + "|" + norm
    functional[functional_key] = int(functional.get(functional_key, 0)) + 1
    if functional_key in recent:
        repeat_in_50 += 1
    recent.append(functional_key)
    if recent.size() > 50:
        recent.pop_front()

func _finish_story(s: AstraGameSession, alternate: bool) -> void:
    var guard := 0
    while not s.story_finished() and guard < 260:
        guard += 1
        var scene := s.story_scene()
        var lines: Array = scene.get("lines", [])
        var index := s.story_line_index()
        if index < lines.size():
            _record(s.case_id, s.day, str(lines[index][0]), str(scene.get("kind", "story")), str(scene.get("id", "story")), s._fill_story(str(lines[index][1])))
        if str(scene.get("kind", "")) == "interlude":
            s.finish_interlude(str(scene.get("interlude", "")), "success")
        elif not Array(scene.get("choices", [])).is_empty() and index >= lines.size() - 1:
            var choices: Array = scene.get("choices", [])
            s.story_choose(choices.size() - 1 if alternate else 0)
        else:
            s.story_next()

func _record_result_lines(s: AstraGameSession, result: Dictionary, intent: String) -> void:
    for raw in result.get("lines", []):
        var line: Dictionary = raw
        _record(s.case_id, s.day, str(line.get("speaker", "")), intent, "conversation", str(line.get("text", "")))

func _clarification_mode(ref: String) -> String:
    return ref.get_slice(":", 0)

func _play_stage(case_id: String, seed_value: int, memory: Dictionary, alternate: bool) -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value)
    s.begin_voyage(memory)
    var guard := 0
    while s.phase != "RESULT" and guard < 500:
        guard += 1
        match s.phase:
            "BRIEFING":
                _finish_story(s, alternate)
                if s.phase == "BRIEFING":
                    s.advance()
            "INTERROGATION":
                var order: Array = s.living_ids().duplicate()
                var leads := s.talk_leads()
                order.sort_custom(func(a, b):
                    var score_a := s.suspicion_score("player", str(a)) + (1.0 if leads.has(str(a)) else 0.0)
                    var score_b := s.suspicion_score("player", str(b)) + (1.0 if leads.has(str(b)) else 0.0)
                    return score_a > score_b)
                for npc_id in order:
                    if s.conversations_left() <= 0:
                        break
                    var opened := s.ask(str(npc_id), "STATEMENT")
                    _record_result_lines(s, opened, "STATEMENT")
                    var qguard := 0
                    while s.followups_left(str(npc_id)) > 0 and qguard < 3:
                        qguard += 1
                        var picked := {}
                        for option in s.question_options(str(npc_id)):
                            if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["CONFRONT","RECORD","WITNESS"]:
                                picked = option
                                break
                        if picked.is_empty():
                            break
                        var intent := str(picked.get("intent", ""))
                        var answer := s.ask(str(npc_id), intent, str(picked.get("ref", "")))
                        _record_result_lines(s, answer, intent)
                s.advance()
            "MEETING":
                var start := s.meeting_feed.size()
                var mguard := 0
                while not s.meeting_over() and mguard < 12:
                    mguard += 1
                    var soft := s.clarification_options()
                    var picked_soft := {}
                    for option in soft:
                        var mode := _clarification_mode(str(option.get("ref", "")))
                        if not clarification_coverage.has(mode):
                            picked_soft = option
                            break
                    if picked_soft.is_empty() and not soft.is_empty():
                        picked_soft = soft[0]
                    var link := AstraTestBots.smart_link(s)
                    if not picked_soft.is_empty():
                        var ref := str(picked_soft.get("ref", ""))
                        if bool(s.intervene("clarify", ref).get("ok", false)):
                            clarification_coverage[_clarification_mode(ref)] = int(clarification_coverage.get(_clarification_mode(ref), 0)) + 1
                    elif s.meeting_actions_left > 0 and link != "":
                        s.intervene("link", link)
                    elif s.meeting_actions_left > 0:
                        var pick := AstraTestBots._smart_moment_pick(s)
                        if not pick.is_empty():
                            s.intervene(str(pick.get("kind", "")), str(pick.get("ref", "")))
                    s.meeting_continue()
                for raw in s.meeting_feed.slice(start):
                    var line: Dictionary = raw
                    _record(s.case_id, s.day, str(line.get("speaker", "")),
                        str(line.get("thread_role", line.get("kind", "meeting"))), "meeting:" + str(line.get("kind", "")), str(line.get("text", "")))
                s.advance()
            "VOTE":
                for statement in s.final_statements():
                    _record(s.case_id, s.day, str(statement.get("id", "")), "FINAL_STATEMENT", "vote", str(statement.get("text", "")))
                AstraTestBots._vote(s, AstraTestBots._player_top(s))
                s.advance()
            "NIGHT":
                AstraTestBots._night(s, true)
                s.advance()
            _:
                s.advance()
    if s.phase == "RESULT":
        _finish_story(s, alternate)
    return s.voyage_memory() if not s.voyage.is_empty() else memory

func _top_lines(counts: Dictionary, minimum: int, limit: int) -> PackedStringArray:
    var keys: Array = counts.keys()
    keys.sort_custom(func(a, b): return int(counts[a]) > int(counts[b]))
    var out: PackedStringArray = []
    for key in keys:
        if int(counts[key]) < minimum or out.size() >= limit:
            break
        out.append("%d\t%s" % [int(counts[key]), str(key)])
    return out

func _probe_missing_clarifications() -> void:
    # Only explores real meeting states. Stop once all seven functional forms
    # have appeared; no synthetic answer text is injected.
    for case_id in ["DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT"]:
        if clarification_coverage.size() >= CLARIFICATION_NAMES.size():
            break
        for offset in range(24):
            if clarification_coverage.size() >= CLARIFICATION_NAMES.size():
                break
            var s := AstraGameSession.new()
            s.setup(case_id, 24111 + offset * 83 + AstraCaseCatalog.stage_index(case_id) * 1000)
            AstraTestBots._finish_morning(s, true)
            if s.phase == "BRIEFING":
                s.advance()
            if s.phase == "INTERROGATION":
                for npc_id in s.living_ids():
                    if s.conversations_left() <= 0:
                        break
                    s.ask(str(npc_id), "STATEMENT")
                    for option in s.question_options(str(npc_id)):
                        if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["RECORD","WITNESS"]:
                            s.ask(str(npc_id), str(option.get("intent", "")), str(option.get("ref", "")))
                            break
                s.advance()
            if s.phase != "MEETING":
                continue
            var guard := 0
            while not s.meeting_over() and guard < 10:
                guard += 1
                var options := s.clarification_options()
                var used := false
                for option in options:
                    var ref := str(option.get("ref", ""))
                    var mode := _clarification_mode(ref)
                    if CLARIFICATION_NAMES.has(mode) and not clarification_coverage.has(mode):
                        var before := s.meeting_feed.size()
                        if bool(s.intervene("clarify", ref).get("ok", false)):
                            clarification_coverage[mode] = 1
                            var added: Array = s.meeting_feed.slice(before)
                            check(not added.is_empty(), "clarification " + mode + " produces a visible answer")
                            used = true
                            break
                if not used and s.meeting_actions_left > 0:
                    var link := AstraTestBots.smart_link(s)
                    if link != "":
                        s.intervene("link", link)
                s.meeting_continue()

func run_exposure() -> void:
    for sample in range(3):
        var memory := {}
        for case_id in PART_I:
            memory = _play_stage(case_id, 21111 + sample * 100003 + AstraCaseCatalog.stage_index(case_id) * 97, memory, sample % 2 == 1)
        memory = {}
        for case_id in PART_II:
            memory = _play_stage(case_id, 22111 + sample * 100003 + AstraCaseCatalog.stage_index(case_id) * 97, memory, sample % 2 == 1)

    _probe_missing_clarifications()
    for mode in CLARIFICATION_NAMES:
        check(int(clarification_coverage.get(mode, 0)) > 0, "runtime clarification coverage includes " + str(CLARIFICATION_NAMES[mode]))

    var exposed := transcript.size()
    var exact_repeat_exposure := 0
    for key in exact:
        if int(exact[key]) > 1:
            exact_repeat_exposure += int(exact[key]) - 1
    var same_speaker_repeat := 0
    for key in speaker_exact:
        if int(speaker_exact[key]) > 1:
            same_speaker_repeat += int(speaker_exact[key]) - 1
    var high_openings := 0
    for key in openings:
        if int(openings[key]) >= 3:
            high_openings += 1

    var out: PackedStringArray = [
        "ASTRA 1.1.1 — HUMAN RHYTHM runtime dialogue exposure",
        "segments\tPART I Stage 2-4 + PART II Stage 5-7",
        "play_style\tSMART-like; sample 2 uses alternate authored choice index",
        "runtime_exposed_lines\t%d" % exposed,
        "exact_repeated_exposure\t%d" % exact_repeat_exposure,
        "same_speaker_repeated_exposure\t%d" % same_speaker_repeat,
        "opening_10_12_chars_3plus_groups\t%d" % high_openings,
        "same_function_within_last_50\t%d" % repeat_in_50,
        "",
        "clarification_runtime_coverage"
    ]
    for mode in CLARIFICATION_NAMES:
        out.append("%s\t%d" % [str(CLARIFICATION_NAMES[mode]), int(clarification_coverage.get(mode, 0))])
    out.append("")
    out.append("top_exact_runtime_lines")
    out.append_array(_top_lines(exact, 2, 30))
    out.append("")
    out.append("top_12char_openings")
    out.append_array(_top_lines(openings, 3, 30))
    out.append("")
    out.append("runtime_transcript")
    out.append_array(transcript)

    check(exposed > 0, "runtime exposure report contains displayed dialogue")
    for retired_generic in [
        "잠깐, 확인된 말과 아직 추측인 부분을 나눠 볼게요.",
        "그 시간쯤 누구를 봤어요? 지나가는 사람이라도요.",
        "그 기록, 지금 같이 열어 볼 수 있어요?",
        "여기까지 확인한 말로 판단해야 한다. 지목받은 사람들의 마지막 말을 듣고, 오늘 격리할 한 사람을 정한다."
    ]:
        check(int(exact.get(_normalize(retired_generic), 0)) == 0,
            "retired generic runtime line stays removed: " + retired_generic)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/dialogue_exposure_111.txt", FileAccess.WRITE)
    file.store_string("\n".join(out))
    file.close()
