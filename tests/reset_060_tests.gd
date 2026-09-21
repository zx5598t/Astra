extends SceneTree
# 0.6.0 new-game hard reset / slot isolation gate.

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_slot_isolation()
    test_hard_reset_contract()
    if failures.is_empty():
        print("ASTRA 0.6.0 RESET TESTS OK · %d checks" % checks)
        quit(0)
    printerr("ASTRA 0.6.0 RESET TESTS FAILED · %d/%d" % [failures.size(),checks])
    quit(1)

func test_slot_isolation() -> void:
    var meta := AstraMetaProgress.new()

    # Legacy v10 memory may migrate to slot 0, but it must never leak into
    # another save slot.
    meta.voyage_memory = {"loops":9,"questions":{"legacy":{"status":"OPEN"}}}
    check(int(meta.voyage_memory_for_slot(0).get("loops",-1)) == 9,
        "legacy memory remains recoverable in slot 0")
    check(meta.voyage_memory_for_slot(1).is_empty(),
        "legacy memory never leaks into slot 1")

    meta.set_voyage_memory_for_slot(0,{
        "loops":7,
        "arrivals":["sena","vale"],
        "relationships":{"old_pair":{"warmth":0.8}},
        "questions":{"old_question":{"status":"OPEN"}},
        "incident_history":[{"id":"old_incident"}],
        "losses":["old_loss"],
        "pinned_question":"old_question"
    })
    meta.set_voyage_memory_for_slot(1,{
        "loops":3,
        "memory_tags":["slot1"],
        "questions":{"slot1_question":{"status":"OPEN"}}
    })

    meta.clear_voyage_memory_for_slot(0)
    check(meta.voyage_memory_for_slot(0).is_empty(),
        "hard reset clears only the chosen slot campaign memory")
    check(int(meta.voyage_memory_for_slot(1).get("loops",-1)) == 3,
        "hard reset preserves other slot")
    check("slot1" in meta.voyage_memory_for_slot(1).get("memory_tags",[]),
        "other-slot narrative memory stays isolated")

func test_hard_reset_contract() -> void:
    var meta := AstraMetaProgress.new()
    meta.set_voyage_memory_for_slot(0,{
        "loops":22,
        "memories":{"mira":"old_destination"},
        "relationships":{"mira|rho":{"warmth":0.9}},
        "questions":{"old_question":{"status":"OPEN"}},
        "incidents":[{"id":"old"}],
        "motives":{"mira":"old"},
        "losses":["rho"],
        "pinned_question":"old_question",
        "chapters":AstraCaseCatalog.CAMPAIGN.duplicate()
    })
    meta.clear_voyage_memory_for_slot(0)

    var s := AstraGameSession.new()
    s.setup("CALIBRATION",9060)
    s.begin_voyage(meta.voyage_memory_for_slot(0))

    check(s.case_id == "CALIBRATION","new game starts at CALIBRATION")
    check(s.campaign_day() == 1,"new game starts at campaign day 1")
    check(s.roster == ["mira","rho","dax","noa"],
        "new game starts with Mira, Jun, Daren and Noa only")
    check(int(s.voyage.get("loop",-1)) == 0,
        "hard reset does not masquerade as an in-fiction loop")
    check(not s.voyage.get("questions",{}).has("old_question"),
        "old questions do not survive hard reset")
    check(not s.voyage.get("relationships",{}).has("mira|rho"),
        "old relationship state does not survive hard reset")
    check(s.casualties.is_empty() and s.isolations.is_empty(),
        "old casualties and isolations do not survive hard reset")

    var residue := s.loop_reset_framing()
    check(str(residue.get("detail","")) != "",
        "in-fiction loop residue remains a separate authored transition")
