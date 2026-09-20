extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_memory_tag_unlock()
    test_pair_defense_callback()
    test_player_pattern_callbacks()
    test_promise_memory()
    if failures.is_empty():
        print("ASTRA 0.5.3 RELATIONSHIP CALLBACK TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.3 RELATIONSHIP CALLBACK TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func _find_family(family: String) -> Dictionary:
    for scene in AstraStorylets053.scenes():
        if str(scene.get("family","")) == family:
            return scene
    return {}

func test_memory_tag_unlock() -> void:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",530110)
    s.begin_voyage({"loops":3})
    s.voyage["scene"] = {}
    s.voyage["met"] = s.roster.duplicate()
    s.voyage["actions"] = 8
    var scene := _find_family("mira_secret_kept")
    check(not scene.is_empty(),"Mira privacy callback exists")
    check(not s._scene_eligible_052(scene,"mira"),"privacy callback stays locked before remembered action")
    s.voyage["memory_tags"].append("mira:respected_medical_privacy")
    check(s._scene_eligible_052(scene,"mira"),"remembered privacy choice unlocks later Mira callback")

func test_pair_defense_callback() -> void:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",530112)
    s.begin_voyage({"loops":3})
    s.voyage["scene"] = {}
    s.voyage["met"] = s.roster.duplicate()
    s.phase = "MEETING"
    s._feed_line("rho","sena","세나의 판단은 적어도 이 기록과는 맞아.","defense")
    check("rho_defended_sena" in s.voyage.get("memory_tags",[]),"Jun defending Sena becomes a relationship memory tag")
    var callback := _find_family("sena_rho_defense_memory")
    s.phase = "EXPLORE"
    check(not callback.is_empty() and s._scene_eligible_052(callback,"sena"),"Sena later has an eligible callback to Jun's defense")

func test_player_pattern_callbacks() -> void:
    var profile := AstraLivingCrew.blank_player_profile()
    profile = AstraLivingCrew.register_player_action(profile,"record")
    profile = AstraLivingCrew.register_player_action(profile,"keep_copy")
    check(AstraLivingCrew.dominant_player_axis(profile) == "evidence_first","behavior profile derives from repeated play")
    check(not AstraLivingCrew.player_remark("mira","evidence_first").is_empty(),"Mira has an evidence-first player callback")
    check(not AstraLivingCrew.player_remark("noa","evidence_first").is_empty(),"other crew retain their own player callback")

func test_promise_memory() -> void:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",530111)
    s.begin_voyage({"loops":3})
    s.voyage["scene"] = {
        "id":"promise_test","speaker":"mira","tag":"player","lines":[],
        "choices":[{"label":"약속","effect":"promise","promise":"tell_injury"}]
    }
    s.voyage["line"] = -1
    check(s.voyage_choose(0),"promise choice resolves")
    check(str(s.voyage.get("promises",{}).get("mira:tell_injury","")) == "active","promise is stored as dialogue memory, not HUD quest")
