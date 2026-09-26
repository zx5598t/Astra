extends SceneTree

# Korean/token leak gate plus an editorial frequency report for human reading.
var failures: Array[String] = []
var checks := 0
var report: PackedStringArray = []

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)

func _initialize() -> void:
    test_source_leaks()
    test_branch_speakers()
    build_editorial_report()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/dialogue_110_report.txt", FileAccess.WRITE)
    file.store_string("\n".join(report))
    file.close()
    if failures.is_empty():
        print("ASTRA DIALOGUE 110 TESTS OK · %d checks" % checks)
        quit(0)
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

func build_editorial_report() -> void:
    var social := FileAccess.get_file_as_string("res://scripts/core/social_lines_080.gd")
    report.append("ASTRA 1.1.0 — dialogue editorial report")
    report.append("")
    report.append("High-frequency functional expression source counts:")
    for phrase in ["확인해요","다시 봐","기록을 봐","근거가 부족","더 확인","아직 모르","맞지 않"]:
        report.append("- %s: %d" % [phrase, social.count(phrase)])
    report.append("")
    report.append("Branch anchors:")
    for anchor in AstraStageStory.BRANCH_ANCHORS:
        var labels: Array[String] = []
        for choice in AstraStageStory.branch_choices(anchor):
            labels.append(str(choice.get("label", "")))
        report.append("- %s: %s" % [anchor, " / ".join(PackedStringArray(labels))])
    report.append("")
    report.append("Automated checks cover raw Josa/token leaks and speaker reachability; naturalness remains a human editorial judgment.")
