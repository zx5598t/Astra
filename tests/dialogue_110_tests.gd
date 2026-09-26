extends SceneTree

# Korean/token leak gate plus an editorial frequency report for human reading.
var failures: Array[String] = []
var checks := 0
var report: PackedStringArray = []
var witness_context_samples := 0
var record_context_samples := 0

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)

func _initialize() -> void:
    test_source_leaks()
    test_branch_speakers()
    test_stance_lines()
    test_question_response_context()
    build_editorial_report()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/dialogue_110_report.txt", FileAccess.WRITE)
    file.store_string("\n".join(report))
    file.close()
    if failures.is_empty():
        print("ASTRA DIALOGUE 110 TESTS OK · %d checks" % checks)
        quit(0)
        return
    for failure in failures:
        printerr("FAIL · " + failure)
    quit(1)

func test_source_leaks() -> void:
    var social := FileAccess.get_file_as_string("res://scripts/core/social_lines_080.gd")
    for marker in ["}|eun","}|i","}|eul","}|wa","}|ro","}|rang","}|ieyo","}|ieot","}|ira","}|iya"]:
        check(marker not in social, "no malformed AstraJosa source marker " + marker)
    var story := FileAccess.get_file_as_string("res://scripts/core/story_content.gd")
    check("동률이면 아무도 격리하지 않습니다." not in story, "obsolete no-isolation tie rule removed")
    check("장소를 고른 뒤 빛나는 조사 지점을" not in story, "obsolete investigation tutorial removed")

func _check_lines(lines: Array, roster: Array, label: String) -> void:
    for line in lines:
        var speaker := str(line[0])
        var text := str(line[1])
        check(speaker in ["","player"] or speaker in roster, "%s speaker %s is in roster" % [label, speaker])
        for marker in ["|eun","|i","|eul","|wa","|ro","|rang","|ieyo","|ieot","|ira","|iya"]:
            check(marker not in text, "%s has no raw marker %s" % [label, marker])
        check("{" not in text and "}" not in text, "%s has no unresolved token" % label)

func test_branch_speakers() -> void:
    for anchor in AstraStageStory.BRANCH_ANCHORS:
        var roster := AstraCaseCatalog.roster(AstraCaseCatalog.get_case(anchor))
        for choice in AstraStageStory.branch_choices(anchor):
            for event in choice.get("consequences", []):
                var followup := str(event.get("followup_scene", ""))
                if followup != "":
                    var scene := AstraStageStory.branch_scene(followup)
                    _check_lines(Array(scene.get("lines", [])), roster, followup)
    var callback_cases := {
        "GLASS_GARDEN":"DEAD_AIR", "SILENT_ORBIT":"ECHO_WARD", "LAST_LIGHT":"RED_SHIFT",
        "BLIND_DECK":"BORROWED_DAYS", "CONTINUITY":"THREE_MINUTES_DARK"
    }
    for case_id in callback_cases:
        var roster := AstraCaseCatalog.roster(AstraCaseCatalog.get_case(case_id))
        var anchor := str(callback_cases[case_id])
        for choice in AstraStageStory.branch_choices(anchor):
            var routes := {anchor:str(choice.get("route_id", ""))}
            var scene := AstraStageStory.cross_stage_callback(case_id, routes)
            _check_lines(Array(scene.get("lines", [])), roster, "callback " + case_id)

func test_stance_lines() -> void:
    for npc_id in AstraCrewCatalog.ORDER:
        for action in ["link","source","defend","other"]:
            var line := AstraSocialLines.stance_shift_line(str(npc_id), str(action), "미라", "노아")
            check(line != "", "stance line exists for %s/%s" % [str(npc_id), str(action)])
            check("{" not in line and "|" not in line, "stance line is fully formatted for %s/%s" % [str(npc_id), str(action)])

func _collect_strings(value: Variant, output: Array[String]) -> void:
    if value is String:
        var text := str(value)
        if text != "":
            output.append(text)
    elif value is Array:
        for item in value:
            _collect_strings(item, output)
    elif value is Dictionary:
        var dict: Dictionary = value
        for key in dict:
            _collect_strings(dict[key], output)

func _pool_size(value: Variant) -> int:
    var lines: Array[String] = []
    _collect_strings(value, lines)
    return lines.size()

func _clarification_pool_size() -> int:
    var total := 0
    var keys := ["m_confirm","m_basis","m_basis_thin","m_settle","m_hold_sighting"]
    for container in [AstraSocialLines.LINES, AstraSocialLines.MORE, AstraSocialLines.MORE2]:
        var root: Dictionary = container
        for npc_id in root:
            var by_person: Dictionary = root[npc_id]
            for key in keys:
                if by_person.has(key):
                    total += _pool_size(by_person[key])
    return total


func _fresh_interrogation(case_id: String, seed_value: int) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value)
    s.begin_voyage({})
    if s.phase == "BRIEFING":
        AstraTestBots._finish_morning(s, true)
        if s.phase == "BRIEFING":
            s.advance()
    return s

func _npc_answer(result: Dictionary, npc_id: String) -> String:
    for raw in result.get("lines", []):
        var line: Dictionary = raw
        if str(line.get("speaker", "")) == npc_id and str(line.get("text", "")).strip_edges() != "":
            return str(line.get("text", "")).strip_edges()
    return ""

func _looks_like_generic_non_answer(text: String) -> bool:
    for phrase in ["기록을 다시 확인", "다시 봐요", "근거가 부족", "더 확인해야", "아직 모르겠어요"]:
        if phrase in text:
            return true
    return false

func test_question_response_context() -> void:
    # WITNESS is the clearest regression for “그 시간에 누구를 봤어요?”.
    # Every current crew member must answer the question itself before any
    # extra personality/expertise texture.
    var seed := 61101
    for npc_raw in AstraCrewCatalog.ORDER:
        var npc_id := str(npc_raw)
        var s := _fresh_interrogation("THREE_MINUTES_DARK", seed)
        seed += 37
        check(s.phase == "INTERROGATION", "context fixture reaches conversation for " + npc_id)
        var opened := s.ask(npc_id, "STATEMENT")
        check(bool(opened.get("ok", false)), "context fixture opens conversation for " + npc_id)
        var result := s.ask(npc_id, "WITNESS")
        check(bool(result.get("ok", false)), "WITNESS is answerable for " + npc_id)
        var answer := _npc_answer(result, npc_id)
        check(answer != "", "WITNESS gets an NPC answer for " + npc_id)
        check(not _looks_like_generic_non_answer(answer), "WITNESS answer is not a generic verification dodge for " + npc_id)
        witness_context_samples += 1

    # RECORD options are only offered when that person actually has a
    # checkable record. If the UI offers it, the answer must return the record
    # itself plus a speaker response, not a generic “check again” line.
    var found := 0
    for case_id in ["DEAD_AIR","GLASS_GARDEN","ECHO_WARD","THREE_MINUTES_DARK"]:
        for sample in range(5):
            if found >= 6:
                break
            var probe := _fresh_interrogation(case_id, 63000 + sample * 211 + AstraCaseCatalog.STAGE_ORDER.find(case_id) * 1009)
            if probe.phase != "INTERROGATION":
                continue
            for npc_raw in probe.living_ids():
                if found >= 6:
                    break
                var npc_id := str(npc_raw)
                var s := _fresh_interrogation(case_id, 63000 + sample * 211 + AstraCaseCatalog.STAGE_ORDER.find(case_id) * 1009)
                s.ask(npc_id, "STATEMENT")
                var record_option := {}
                for option in s.question_options(npc_id):
                    if str(option.get("intent", "")) == "RECORD" and bool(option.get("enabled", false)):
                        record_option = option
                        break
                if record_option.is_empty():
                    continue
                var result := s.ask(npc_id, "RECORD", str(record_option.get("ref", "")))
                check(bool(result.get("ok", false)), "RECORD option executes for %s/%s" % [case_id, npc_id])
                check(not Dictionary(result.get("record", {})).is_empty(), "RECORD question returns the opened record for %s/%s" % [case_id, npc_id])
                var answer := _npc_answer(result, npc_id)
                check(answer != "", "RECORD gets an NPC answer for %s/%s" % [case_id, npc_id])
                check(not _looks_like_generic_non_answer(answer), "RECORD answer is not a generic verification dodge for %s/%s" % [case_id, npc_id])
                found += 1
                record_context_samples += 1
    check(record_context_samples >= 3, "runtime samples at least three actual RECORD question/answer paths")

func build_editorial_report() -> void:
    var authored: Array[String] = []
    for pool in [
        AstraSocialLines.REVIEW_VOICE, AstraSocialLines.RESISTANCE, AstraSocialLines.LINES,
        AstraSocialLines.MORE, AstraSocialLines.MORE2, AstraSocialLines.RECORD_OTHER,
        AstraSocialLines.HEARSAY_LINES, AstraSocialLines.ISOLATED_STATE_LINES,
        AstraSocialLines.SHIELD_LINES, AstraSocialLines.ANALYST_LINES,
        AstraSocialLines.LINK_LINES, AstraSocialLines.LAST_LINES, AstraSocialLines.STANCE_SHIFT_110
    ]:
        _collect_strings(pool, authored)

    var exact_counts := {}
    var prefix_counts := {}
    for line in authored:
        exact_counts[line] = int(exact_counts.get(line, 0)) + 1
        var compact := line.strip_edges()
        var prefix_len := mini(12, compact.length())
        var prefix := compact.left(prefix_len)
        if prefix != "":
            prefix_counts[prefix] = int(prefix_counts.get(prefix, 0)) + 1

    var duplicate_groups := 0
    var repeated_prefixes := 0
    for line in exact_counts:
        if int(exact_counts[line]) > 1:
            duplicate_groups += 1
    for prefix in prefix_counts:
        if int(prefix_counts[prefix]) >= 3:
            repeated_prefixes += 1

    report.append("ASTRA 1.1.0 — dialogue editorial report")
    report.append("")
    report.append("Authored line population: %d" % authored.size())
    report.append("Exact duplicate groups: %d" % duplicate_groups)
    report.append("Same-opening groups (first 12 chars, 3+ uses): %d" % repeated_prefixes)
    report.append("")
    report.append("High-frequency functional expressions across authored pools:")
    for phrase in ["확인","다시 보","기록","근거","아직","모르","맞지 않"]:
        var count := 0
        for line in authored:
            count += line.count(phrase)
        report.append("- %s: %d" % [phrase, count])
    report.append("")
    report.append("High-exposure authored pools:")
    report.append("- clarification responses: %d" % _clarification_pool_size())
    report.append("- Link responses: %d" % _pool_size(AstraSocialLines.LINK_LINES))
    report.append("- final statements: %d" % _pool_size(AstraSocialLines.LAST_LINES))
    report.append("- stance-change lines: %d" % _pool_size(AstraSocialLines.STANCE_SHIFT_110))
    report.append("- runtime WITNESS question/answer samples: %d" % witness_context_samples)
    report.append("- runtime RECORD question/answer samples: %d" % record_context_samples)
    report.append("")
    report.append("Branch anchors:")
    for anchor in AstraStageStory.BRANCH_ANCHORS:
        var labels: Array[String] = []
        for choice in AstraStageStory.branch_choices(anchor):
            labels.append(str(choice.get("label", "")))
        report.append("- %s: %s" % [anchor, " / ".join(PackedStringArray(labels))])
    report.append("")
    report.append("Automation reports repetition/exposure only. Korean naturalness and AI-like symmetry remain a human editorial judgement.")

