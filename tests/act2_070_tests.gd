extends SceneTree
# 0.7.0 ACT II progression: Day 8 stays locked until Day 7 (LAST_LIGHT) is
# completed in that save slot, Day 8-13 unlock sequentially the same way
# Act I already does, and no new save schema/version was needed (ACT is
# derived, see AstraVoyageContent.act_for) — verified against a real
# AstraMetaProgress round trip, not just read from the source.

var failures: Array[String] = []
var checks := 0
const PATH := "user://astra_act2_070_test.cfg"

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func _initialize() -> void:
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    test_locked_until_last_light()
    test_sequential_unlock_through_act2()
    test_save_schema_unchanged()
    if failures.is_empty():
        print("ASTRA ACT2 070 TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures:
        printerr("FAIL · " + failure)
    quit(1)

func test_locked_until_last_light() -> void:
    var meta := AstraMetaProgress.new(PATH)
    var slot := 0
    check(not meta.is_case_unlocked_for_slot("DEAD_AIR", slot),"DEAD_AIR locked until CALIBRATION is recorded for this slot")
    meta.set_voyage_memory_for_slot(slot, {"chapters": [AstraCaseCatalog.CALIBRATION]})
    check(meta.is_case_unlocked_for_slot("DEAD_AIR", slot),"DEAD_AIR (Day 2) unlocks once CALIBRATION is recorded")
    for case_id in AstraCaseCatalog.CAMPAIGN:
        if case_id == "SECOND_WATCH":
            break
        check(not meta.is_case_unlocked_for_slot("SECOND_WATCH", slot),"SECOND_WATCH stays locked before %s is recorded" % case_id)
        var memory: Dictionary = meta.voyage_memory_for_slot(slot)
        var chapters: Array = Array(memory.get("chapters", []))
        chapters.append(case_id)
        memory["chapters"] = chapters
        meta.set_voyage_memory_for_slot(slot, memory)
    check(meta.is_case_unlocked_for_slot("SECOND_WATCH", slot),"SECOND_WATCH unlocks once LAST_LIGHT is recorded complete")
    check(not meta.is_case_unlocked_for_slot("BORROWED_DAYS", slot),"BORROWED_DAYS still locked before SECOND_WATCH is recorded")

func test_sequential_unlock_through_act2() -> void:
    var meta := AstraMetaProgress.new(PATH)
    var slot := 1
    meta.set_voyage_memory_for_slot(slot, {"chapters": [AstraCaseCatalog.CALIBRATION]})
    for case_id in AstraCaseCatalog.CAMPAIGN:
        check(meta.is_case_unlocked_for_slot(case_id, slot),"%s unlocked once the prior chapter is recorded" % case_id)
        var memory: Dictionary = meta.voyage_memory_for_slot(slot)
        var chapters: Array = Array(memory.get("chapters", []))
        chapters.append(case_id)
        meta.set_voyage_memory_for_slot(slot, {"chapters": chapters})
    check(meta.is_case_unlocked_for_slot("THRESHOLD", slot),"THRESHOLD (Day 13) reachable after playing straight through")

func test_save_schema_unchanged() -> void:
    # 0.7.0 deliberately adds no new save fields for ACT II itself (ACT is
    # derived from campaign_day, not persisted) — a save written before this
    # version's campaign extension must still load cleanly.
    check(AstraMetaProgress.SAVE_VERSION >= 11,"save schema is at least v11 — ACT II needed no migration (0.8.0 moved to v12)")
    var meta := AstraMetaProgress.new(PATH)
    meta.calibration_completed = true
    meta.save_data()
    var reloaded := AstraMetaProgress.new(PATH)
    reloaded.load_data()
    check(reloaded.calibration_completed,"existing save fields round-trip unchanged")
    check(AstraCaseCatalog.CAMPAIGN.size() == 12,"CAMPAIGN.size() reflects the full ACT I + ACT II length")
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
