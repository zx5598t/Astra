extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_mira_volume_and_mix()
    test_mira_phrase_and_agency_audit()
    test_mira_private_depth()
    test_mira_tones()
    test_mira_exposure_cap()
    test_mira_null_and_offline_regression()
    test_early_game_text_guard()
    if failures.is_empty():
        print("ASTRA 0.5.3 MIRA CONTENT TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.3 MIRA CONTENT TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func _counts() -> Dictionary:
    var result := {}
    for scene in AstraVoyageContent.all_scenes():
        var speaker := str(scene.get("speaker",""))
        if speaker == "":
            continue
        result[speaker] = int(result.get(speaker,0)) + 1
    return result

func test_mira_volume_and_mix() -> void:
    var all := AstraVoyageContent.all_scenes()
    var counts := _counts()
    var mira_total := int(counts.get("mira",0))
    var other_max := 0
    var other_sum := 0
    var other_n := 0
    for npc_id in AstraCrewCatalog.ORDER:
        if npc_id == "mira":
            continue
        var count := int(counts.get(npc_id,0))
        other_max = maxi(other_max,count)
        other_sum += count
        other_n += 1
    var avg := float(other_sum) / maxf(1.0,float(other_n))
    check(all.size() >= 470 and all.size() <= 650,"cumulative authored library remains inside maintained target (%d)" % all.size())
    check(mira_total >= 80 and mira_total <= 100,"Mira emotional-anchor library remains deep but bounded across later releases (%d)" % mira_total)
    check(mira_total >= other_max,"Mira is joint or sole largest authored speaker pool (%d vs %d)" % [mira_total,other_max])
    check(float(mira_total) >= avg + 10.0,"Mira pool is meaningfully above other-crew average (%.1f)" % avg)
    var groups := AstraStorylets053.mira_group_counts()
    for group in ["CARE","DAILY","MEDICAL","PLAYER","RELATIONSHIP","ECHO","CONFLICT"]:
        check(int(groups.get(group,0)) > 0,"Mira has " + group + " authored material")
    var player_specific := 0
    var echo_count := 0
    var conflict_count := 0
    var pair_count := 0
    for scene in AstraVoyageContent.all_scenes():
        if str(scene.get("speaker","")) == "mira" and bool(scene.get("player_specific",false)):
            player_specific += 1
        if (str(scene.get("speaker","")) == "mira" or "mira" in scene.get("participants",[])) and str(scene.get("tag","")) == "echo":
            echo_count += 1
        if (str(scene.get("speaker","")) == "mira" or "mira" in scene.get("participants",[])) and str(scene.get("tag","")) == "conflict":
            conflict_count += 1
        if (str(scene.get("speaker","")) == "mira" or str(scene.get("target","")) == "mira" or "mira" in scene.get("participants",[])) and str(scene.get("tag","")) in ["pair","trio"]:
            pair_count += 1
    check(player_specific >= 10,"Mira has substantial player-specific authored scenes (%d)" % player_specific)
    check(echo_count >= 4,"Mira has multiple echo scenes (%d)" % echo_count)
    check(conflict_count >= 4,"Mira can meaningfully conflict instead of always agreeing (%d)" % conflict_count)
    check(pair_count >= 15,"Mira has an independent relationship network (%d pair/trio scenes)" % pair_count)
    print("MIRA CONTENT · total=%d · player_specific=%d · echo=%d · conflict=%d · pair/trio=%d · groups=%s" % [mira_total,player_specific,echo_count,conflict_count,pair_count,str(groups)])

func test_mira_phrase_and_agency_audit() -> void:
    var phrases := {
        "괜찮아요":0, "잠깐":0, "무리하지":0, "확인할게":0,
        "잃고 싶지":0, "사랑":0
    }
    var agency := 0
    var player_only := 0
    var mira_speaker := 0
    for scene in AstraVoyageContent.all_scenes():
        if str(scene.get("speaker","")) != "mira":
            continue
        mira_speaker += 1
        if bool(scene.get("agency",false)):
            agency += 1
        if bool(scene.get("player_specific",false)):
            player_only += 1
        var text := str(scene.get("action",""))
        for line in scene.get("lines",[]):
            if line is Array and line.size() > 1:
                text += " " + str(line[1])
        for phrase in phrases:
            phrases[phrase] = int(phrases[phrase]) + text.count(str(phrase))
    check(agency >= 3,"Mira has independent authored decisions, not only player-facing care (%d agency scenes)" % agency)
    check(player_only < mira_speaker / 2,"less than half of Mira speaker scenes exist only to focus on the player (%d/%d)" % [player_only,mira_speaker])
    check(int(phrases["괜찮아요"]) <= 8,"Mira does not lean on '괜찮아요?' as a catchphrase (%d)" % int(phrases["괜찮아요"]))
    check(int(phrases["잠깐"]) <= 8,"Mira '잠깐' repetition stays restrained (%d)" % int(phrases["잠깐"]))
    check(int(phrases["잃고 싶지"]) <= 1 and int(phrases["사랑"]) == 0,"0.5.3 avoids forced romance-confession language")
    print("MIRA PHRASE AUDIT · %s · agency=%d · player_specific=%d/%d" % [str(phrases),agency,player_only,mira_speaker])

func test_mira_private_depth() -> void:
    var count := AstraPrivateEvents.count_for("mira")
    check(count >= 10 and count <= 14,"Mira private pool reaches 10-14 target (%d)" % count)
    for npc_id in AstraCrewCatalog.ORDER:
        check(AstraPrivateEvents.count_for(npc_id) >= 4,str(npc_id) + " retains a non-empty private life")

func _tone_scene() -> Dictionary:
    for scene in AstraStorylets053.scenes():
        if str(scene.get("family","")) == "mira_wrist_first":
            return scene
    return {}

func test_mira_tones() -> void:
    var s := AstraGameSession.new()
    s.setup("ECHO_WARD",530053)
    s.begin_voyage({"loops":2})
    var scene := _tone_scene()
    check(not scene.is_empty(),"Mira tone test scene exists")
    s.voyage["bonds"]["mira"] = 0.5
    s.voyage["echo"]["mira"] = {"familiarity":0.6,"trust":0.5,"protection":0.1,"conflict":0.0,"grief":0.0,"tags":[]}
    var warm := s._apply_scene_variants(scene,"mira")
    s.voyage["bonds"]["mira"] = 0.0
    s.voyage["echo"]["mira"] = {"familiarity":0.0,"trust":0.0,"protection":0.0,"conflict":0.0,"grief":0.0,"tags":[]}
    var professional := s._apply_scene_variants(scene,"mira")
    s.voyage["bonds"]["mira"] = -0.4
    s.voyage["echo"]["mira"] = {"familiarity":0.0,"trust":0.0,"protection":0.0,"conflict":0.5,"grief":0.0,"tags":[]}
    var strained := s._apply_scene_variants(scene,"mira")
    var a := str(Array(warm.get("lines",[]))[0][1])
    var b := str(Array(professional.get("lines",[]))[0][1])
    var c := str(Array(strained.get("lines",[]))[0][1])
    check(a != b and b != c and a != c,"WARM / PROFESSIONAL / STRAINED use distinct Mira wording")

func test_mira_exposure_cap() -> void:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",530054)
    s.begin_voyage({"loops":3})
    s.voyage["scene"] = {}
    s.voyage["room"] = "medbay"
    s.voyage["met"] = s.roster.duplicate()
    s.voyage["actions"] = 8
    for i in range(10):
        s.voyage["scene"] = {}
        s.voyage_talk("mira")
    check(int(s.voyage.get("mira_optional_exposure",0)) <= 4,"ordinary loop caps Mira optional exposure (%d)" % int(s.voyage.get("mira_optional_exposure",0)))

func test_mira_null_and_offline_regression() -> void:
    var null_seen := false
    for seed_value in range(160):
        var truth := AstraCaseGenerator.generate("LAST_LIGHT",880000 + seed_value * 13,[],"STANDARD")
        if "mira" in truth.get("nulls",[]):
            null_seen = true
            break
    check(null_seen,"Mira remains eligible for Null role; no heroine plot armor")
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",530055)
    s.begin_voyage({"loops":2})
    s.voyage["scene"] = {}
    s.voyage["room"] = "medbay"
    s.voyage["met"] = s.roster.duplicate()
    s.crew["mira"].status = AstraCrewMember.STATUS_ISOLATED
    var any_scene := {}
    for scene in AstraStorylets053.scenes():
        if str(scene.get("speaker","")) == "mira":
            any_scene = scene
            break
    check(not s._scene_eligible_052(any_scene,"mira"),"isolated Mira cannot appear in later living scenes")

func test_early_game_text_guard() -> void:
    var calibration := 0
    var dead_air := 0
    for scene in AstraStorylets053.scenes():
        var chapters: Array = scene.get("chapters",[])
        if "CALIBRATION" in chapters:
            calibration += 1
        if "DEAD_AIR" in chapters:
            dead_air += 1
    check(calibration == 0,"0.5.3 adds no CALIBRATION storylet load")
    check(dead_air <= 2,"DEAD AIR receives only a tiny optional 0.5.3 pool (%d)" % dead_air)
