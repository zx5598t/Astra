extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_visible_relationship_feedback()
    test_aggregation_and_tension()
    test_consequence_and_opinion_visibility()
    test_codex_actual_seen_only()
    test_hidden_state_leak()
    if failures.is_empty():
        print("ASTRA 0.5.6 ECHOES TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.6 ECHOES TESTS FAILED · %d/%d" % [failures.size(),checks])
        quit(1)

func _session() -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",560601)
    s.begin_voyage({"loops":3,"codex_entries_unlocked":[]})
    s.voyage["scene"] = {}
    s.voyage["met"] = s.roster.duplicate()
    return s

func _scene_by_id(scene_id: String) -> Dictionary:
    for scene in AstraVoyageContent.all_scenes():
        if str(scene.get("id","")) == scene_id:
            return Dictionary(scene).duplicate(true)
    return {}

func test_visible_relationship_feedback() -> void:
    var s := _session()
    var authored := _scene_by_id("pair_2")
    check(not authored.is_empty(),"authored rho/sena pair scene exists")
    s._voyage_scene(authored)
    var summary := s.daily_social_summary(s.day)
    var rows: Array = summary.get("relationship_changes",[])
    check(not rows.is_empty(),"actual authored pair scene produces public relationship summary")
    var row: Dictionary = rows[0] if not rows.is_empty() else {}
    check(str(row.get("pair","")) != "","relationship summary names the pair")
    check(str(row.get("text","")) != "","relationship summary has qualitative text")
    check(not row.has("magnitude") and not row.has("source"),"public relationship row strips raw magnitude and source ids")
    var codex_ids: Array = s.codex_unlock_events().map(func(x): return str(x.get("id","")))
    check("rho_sena_working_after_vote" in codex_ids,"visible rho/sena relationship milestone can unlock observation Codex")

func test_aggregation_and_tension() -> void:
    var s := _session()
    s._adjust_relationship("mira","lyra","trust",0.01,"small-a",true,false)
    s._adjust_relationship("mira","lyra","trust",0.01,"small-b",true,false)
    s._adjust_relationship("mira","lyra","trust",0.01,"small-c",true,false)
    var summary := s.daily_social_summary(s.day)
    var pair_count := 0
    for row in summary.get("relationship_changes",[]):
        if str(row.get("pair","")) == "미라 ↔ 마렌":
            pair_count += 1
    check(pair_count == 1,"same pair/day/axis small changes aggregate to one row")

    var conflict := _scene_by_id("053_mira_sena_priority")
    check(not conflict.is_empty(),"authored visible conflict scene exists")
    s._voyage_scene(conflict)
    summary = s.daily_social_summary(s.day)
    var tensions: Array = summary.get("active_tensions",[])
    check(not tensions.is_empty(),"witnessed authored conflict can appear as active tension")
    check(str(tensions[0].get("kind","")) == "tension","active tension is qualitative relationship kind")

func test_consequence_and_opinion_visibility() -> void:
    var s := _session()
    s._apply_consequence_event({
        "id":"056-visible-followup","timing":"DELAYED","who":"mira",
        "source_scene":"056-test-choice",
        "note":"미라는 이전 선택을 기억하고 먼저 기록을 건넸다."
    },false)
    s.voyage["opinion_changes"].append({
        "actor":"noa","target":"rho","reason_tag":"new_evidence",
        "visible":true,"day":s.day
    })
    var summary := s.daily_social_summary(s.day)
    check(Array(summary.get("consequences",[])).size() == 1,"player-linked consequence appears once")
    check("먼저 기록을 건넸다" in str(summary["consequences"][0].get("text","")),"consequence uses authored human-readable note")
    check(Array(summary.get("opinion_changes",[])).size() == 1,"visible opinion change is included")
    check("판단" in str(summary["opinion_changes"][0].get("text","")),"opinion change is translated to human-readable wording")

func test_codex_actual_seen_only() -> void:
    var s := _session()
    s.voyage["codex_unlocks_pending"] = []
    s.voyage["codex_known"] = []
    var unseen_id := "mira_self_neglect"
    check(unseen_id not in s.codex_unlock_events().map(func(x): return str(x.get("id",""))),"candidate lore starts locked")
    var scene := _scene_by_id("054_mira_self_neglect_1")
    check(not scene.is_empty(),"micro-arc Codex trigger scene exists")
    s._voyage_scene(scene)
    var ids: Array = s.codex_unlock_events().map(func(x): return str(x.get("id","")))
    check(unseen_id in ids,"actually displayed storylet unlocks Codex")
    var before := ids.size()
    s._voyage_scene(scene)
    var after := s.codex_unlock_events().size()
    check(after == before,"replaying same storylet does not duplicate Codex unlock")
    check(AstraCodex.unlocks_for_scene("054_mira_self_neglect_1").has(unseen_id),"Codex trigger is explicit authored scene mapping")

func test_hidden_state_leak() -> void:
    var s := _session()
    s._adjust_relationship("rho","sena","tension",0.05,"secret-internal-source",true,true)
    s.voyage["motives"] = {"rho":{"motive":"HIDE_MISTAKE","state":"REVEALED"}}
    var public_summary := s.daily_social_summary(s.day)
    var serialized := JSON.stringify(public_summary).to_lower()
    for forbidden in ["magnitude","secret-internal-source","hide_mistake","nulls","motive","probability","relationships"]:
        check(forbidden not in serialized,"public social summary does not leak " + forbidden)
    for row in public_summary.get("relationship_changes",[]):
        check(not row.has("trust") and not row.has("tension") and not row.has("respect") and not row.has("comfort") and not row.has("protectiveness"),"public rows contain no raw relationship floats")
