extends SceneTree

# ASTRA 1.1.0 LIVING PATHS — authored/runtime exposure report.
# Runs representative real GameSession campaigns through the same story,
# conversation, meeting, vote and night paths used by SMART QA.
var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_exposure_balancer()
    run_report()
    if failures.is_empty():
        print("ASTRA CONTENT EXPOSURE 110 OK · %d checks" % checks)
        quit(0)
        return
    for failure in failures:
        printerr("FAIL · " + failure)
    printerr("ASTRA CONTENT EXPOSURE 110 FAILED · %d/%d" % [failures.size(), checks])
    quit(1)


func test_exposure_balancer() -> void:
    var s := AstraGameSession.new()
    s.setup("THREE_MINUTES_DARK", 61001)
    s.begin_voyage({})
    s.voyage["speaker_exposure"] = {"mira":4,"noa":3,"vale":0}
    var before_truth := JSON.stringify(s.truth)
    var candidates: Array = [
        {"id":"x_mira","speaker":"mira","lines":[["mira","x"]]},
        {"id":"x_noa","speaker":"noa","lines":[["noa","x"]]},
        {"id":"x_vale","speaker":"vale","lines":[["vale","x"]]}
    ]
    var picked := s._pick_exposure_balanced_scene(candidates, "exposure-test")
    check(str(picked.get("speaker", "")) == "vale", "optional scheduler prefers the least-exposed eligible speaker")
    check(int(s.voyage.get("speaker_exposure", {}).get("vale", 0)) == 1, "optional scheduler records exposure after selection")
    check(JSON.stringify(s.truth) == before_truth, "exposure scheduling leaves case truth unchanged")

func _count_strings(value: Variant) -> int:
    if value is String:
        return 1 if str(value) != "" else 0
    var total := 0
    if value is Array:
        for item in value:
            total += _count_strings(item)
    elif value is Dictionary:
        var data: Dictionary = value
        for key in data:
            total += _count_strings(data[key])
    return total

func _meeting_variants(npc_id: String) -> int:
    var total := 0
    for container in [AstraSocialLines.LINES, AstraSocialLines.MORE, AstraSocialLines.MORE2]:
        var root_data: Dictionary = container
        var by_person: Dictionary = root_data.get(npc_id, {})
        for key in by_person:
            if str(key).begins_with("m_"):
                total += _count_strings(by_person[key])
    total += _count_strings(Dictionary(AstraSocialLines.LINK_LINES.get(npc_id, {})))
    total += _count_strings(Dictionary(AstraSocialLines.LAST_LINES.get(npc_id, {})))
    total += _count_strings(Dictionary(AstraSocialLines.STANCE_SHIFT_110.get(npc_id, {})))
    return total

func _is_optional_personal(scene: Dictionary) -> bool:
    return str(scene.get("category", "")) in ["PERSONAL","RELATIONSHIP"]

func _authored_counts() -> Dictionary:
    var counts := {}
    var personal := {}
    for npc_id in AstraCrewCatalog.ORDER:
        counts[str(npc_id)] = 0
        personal[str(npc_id)] = 0
    for raw in AstraVoyageContent.all_scenes():
        var scene: Dictionary = raw
        var who := str(scene.get("speaker", ""))
        if not counts.has(who):
            continue
        counts[who] = int(counts[who]) + 1
        if _is_optional_personal(scene):
            personal[who] = int(personal[who]) + 1
    return {"all":counts,"personal":personal}

func _scene_speakers(scene: Dictionary) -> Array[String]:
    var speakers: Array[String] = []
    var primary := str(scene.get("speaker", ""))
    if primary in AstraCrewCatalog.ORDER and primary not in speakers:
        speakers.append(primary)
    for line in scene.get("lines", []):
        var who := str(line[0])
        if who in AstraCrewCatalog.ORDER and who not in speakers:
            speakers.append(who)
    return speakers

func _record_story_scene(scene: Dictionary, visible: Dictionary, personal: Dictionary) -> void:
    var scene_id := str(scene.get("id", ""))
    if scene_id == "":
        return
    var is_personal := str(scene.get("category", "")) in ["PERSONAL","RELATIONSHIP"] or str(scene.get("kind", "")) in ["micro_arc","relationship"]
    for who in _scene_speakers(scene):
        if not visible.has(who):
            visible[who] = {}
        visible[who][scene_id] = true
        if is_personal:
            if not personal.has(who):
                personal[who] = {}
            personal[who][scene_id] = true

func _finish_story_recording(s: AstraGameSession, visible: Dictionary, personal: Dictionary) -> void:
    var guard := 0
    while not s.story_finished() and guard < 220:
        guard += 1
        var scene := s.story_scene()
        _record_story_scene(scene, visible, personal)
        if str(scene.get("kind", "")) == "interlude":
            s.finish_interlude(str(scene.get("interlude", "")), "success")
        elif not Array(scene.get("choices", [])).is_empty():
            s.story_choose(0)
        else:
            s.story_next()

func _record_meeting_lines(s: AstraGameSession, meeting_lines: Dictionary) -> void:
    for raw in s.meeting_feed:
        var line: Dictionary = raw
        var who := str(line.get("speaker", ""))
        if who in AstraCrewCatalog.ORDER:
            meeting_lines[who] = int(meeting_lines.get(who, 0)) + 1

func _drive_smart(s: AstraGameSession, visible: Dictionary, personal: Dictionary, meeting_lines: Dictionary) -> void:
    var steps := 0
    while s.phase != "RESULT" and steps < 400:
        steps += 1
        match s.phase:
            "BRIEFING":
                _finish_story_recording(s, visible, personal)
                if s.phase == "BRIEFING":
                    s.advance()
            "INTERROGATION":
                var order: Array = s.living_ids().duplicate()
                var leads := s.talk_leads()
                order.sort_custom(func(a, b):
                    return s.suspicion_score("player", str(a)) + (1.0 if leads.has(str(a)) else 0.0) > s.suspicion_score("player", str(b)) + (1.0 if leads.has(str(b)) else 0.0)
                )
                for npc_id in order:
                    if s.conversations_left() <= 0:
                        break
                    s.ask(str(npc_id), "STATEMENT")
                    var guard := 0
                    while s.followups_left(str(npc_id)) > 0 and guard < 4:
                        guard += 1
                        var options := s.question_options(str(npc_id))
                        var picked := {}
                        for option in options:
                            if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["CONFRONT","RECORD"]:
                                picked = option
                                break
                        if picked.is_empty():
                            for option in options:
                                if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["WITNESS","REASSURE","YESTERDAY"]:
                                    picked = option
                                    break
                        if picked.is_empty():
                            break
                        s.ask(str(npc_id), str(picked.get("intent", "")), str(picked.get("ref", "")))
                s.advance()
            "MEETING":
                AstraTestBots._smart_meeting(s)
                _record_meeting_lines(s, meeting_lines)
                s.advance()
            "VOTE":
                AstraTestBots._vote(s, AstraTestBots._player_top(s))
                s.advance()
            "NIGHT":
                AstraTestBots._night(s, true)
                s.advance()
            _:
                s.advance()
    if s.phase == "RESULT":
        _finish_story_recording(s, visible, personal)


func _run_winning_stage(case_id: String, seed_base: int, memory: Dictionary, visible: Dictionary, personal: Dictionary, meeting_lines: Dictionary) -> AstraGameSession:
    var last: AstraGameSession = null
    for attempt in range(8):
        var local_visible := {}
        var local_personal := {}
        var local_meeting := {}
        var s := AstraGameSession.new()
        s.setup(case_id, seed_base + attempt * 100003)
        s.begin_voyage(memory)
        _drive_smart(s, local_visible, local_personal, local_meeting)
        last = s
        if s.outcome == "WIN":
            for who in local_visible:
                if not visible.has(who): visible[who] = {}
                for scene_id in Dictionary(local_visible[who]): visible[who][scene_id] = true
            for who in local_personal:
                if not personal.has(who): personal[who] = {}
                for scene_id in Dictionary(local_personal[who]): personal[who][scene_id] = true
            for who in local_meeting:
                meeting_lines[who] = int(meeting_lines.get(who, 0)) + int(local_meeting[who])
            return s
    return last

func _campaign(seed_base: int, start_memory: Dictionary = {}) -> Dictionary:
    var memory: Dictionary = start_memory.duplicate(true)
    var visible := {}
    var personal := {}
    var meeting_lines := {}
    var stage_offset := 0
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        var s := _run_winning_stage(str(case_id), seed_base + stage_offset * 997, memory, visible, personal, meeting_lines)
        check(s != null and s.outcome == "WIN", "exposure campaign clears " + str(case_id))
        if s != null and s.outcome == "WIN":
            memory = s.voyage_memory()
        stage_offset += 1
    return {"memory":memory,"visible":visible,"personal":personal,"meeting_lines":meeting_lines}


func _available_stage_count(npc_id: String) -> int:
    var total := 0
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        if npc_id in AstraCaseCatalog.roster(AstraCaseCatalog.get_case(case_id)):
            total += 1
    return total

func _count_visible(map: Dictionary, npc_id: String) -> int:
    return Dictionary(map.get(npc_id, {})).size()

func _count_personal_visible(map: Dictionary, npc_id: String) -> int:
    return Dictionary(map.get(npc_id, {})).size()

func _union_maps(maps: Array) -> Dictionary:
    var result := {}
    for raw in maps:
        var source: Dictionary = raw
        for npc_id in source:
            if not result.has(npc_id):
                result[npc_id] = {}
            for scene_id in Dictionary(source[npc_id]):
                result[npc_id][scene_id] = true
    return result

func _new_count(first: Dictionary, second: Dictionary, npc_id: String) -> int:
    var total := 0
    var a: Dictionary = first.get(npc_id, {})
    var b: Dictionary = second.get(npc_id, {})
    for scene_id in b:
        if not a.has(scene_id):
            total += 1
    return total

func run_report() -> void:
    var authored := _authored_counts()
    var first := _campaign(61100)
    var repeat := _campaign(71100, Dictionary(first.get("memory", {})))
    var sample_c := _campaign(81100)
    var sample_d := _campaign(91100)
    var first_visible: Dictionary = first.get("visible", {})
    var repeat_visible: Dictionary = repeat.get("visible", {})
    var first_personal: Dictionary = first.get("personal", {})
    var repeat_personal: Dictionary = repeat.get("personal", {})
    var sampled_union := _union_maps([
        first_visible, repeat_visible,
        Dictionary(sample_c.get("visible", {})),
        Dictionary(sample_d.get("visible", {}))
    ])

    var lines: PackedStringArray = []
    lines.append("ASTRA 1.1.0 — character content exposure report")
    lines.append("Representative runtime measurement: first campaign + continued repeat campaign + 2 independent campaign samples.")
    lines.append("runtime_reached_sample counts actual displayed story_queue scenes observed in those campaigns; it is a measured sample, not a proof of exhaustive reachability.")
    lines.append("")
    lines.append("id\tavailable_stages\tauthored_library\truntime_reached_sample\tfirst_visible\tfirst_per_available_stage\trepeat_visible\tnew_in_repeat\tpersonal_authored\tpersonal_first\tpersonal_repeat\tmeeting_first_lines\tmeeting_repeat_lines\tmeeting_authored_variants")

    var total_new := 0
    for npc_raw in AstraCrewCatalog.ORDER:
        var npc_id := str(npc_raw)
        var available_stages := _available_stage_count(npc_id)
        var authored_count := int(Dictionary(authored.get("all", {})).get(npc_id, 0))
        var personal_authored := int(Dictionary(authored.get("personal", {})).get(npc_id, 0))
        var runtime_sampled := _count_visible(sampled_union, npc_id)
        var first_count := _count_visible(first_visible, npc_id)
        var first_per_stage := float(first_count) / float(maxi(1, available_stages))
        var repeat_count := _count_visible(repeat_visible, npc_id)
        var new_repeat := _new_count(first_visible, repeat_visible, npc_id)
        var personal_first := _count_personal_visible(first_personal, npc_id)
        var personal_repeat := _count_personal_visible(repeat_personal, npc_id)
        var meeting_first := int(Dictionary(first.get("meeting_lines", {})).get(npc_id, 0))
        var meeting_repeat := int(Dictionary(repeat.get("meeting_lines", {})).get(npc_id, 0))
        var meeting_variants := _meeting_variants(npc_id)
        total_new += new_repeat
        lines.append("%s\t%d\t%d\t%d\t%d\t%.2f\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d" % [
            npc_id, available_stages, authored_count, runtime_sampled, first_count, first_per_stage,
            repeat_count, new_repeat, personal_authored, personal_first, personal_repeat,
            meeting_first, meeting_repeat, meeting_variants
        ])
        check(authored_count > 0, npc_id + " has authored content")
        check(runtime_sampled > 0, npc_id + " appears in sampled runtime story scenes")
        check(meeting_variants > 0, npc_id + " has authored meeting dialogue variants")
        check(meeting_first > 0, npc_id + " speaks during representative first-campaign meetings")
    check(total_new > 0, "continued repeat campaign exposes at least one new displayed story scene")
    check(_count_visible(sampled_union, "vale") > 0, "Soren runtime exposure is non-zero")
    check(_count_visible(sampled_union, "eli") > 0, "Lucan runtime exposure is non-zero")
    lines.append("")
    lines.append("new_in_repeat_total\t%d" % total_new)

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/content_exposure_110.txt", FileAccess.WRITE)
    file.store_string("\n".join(lines))
    file.close()

