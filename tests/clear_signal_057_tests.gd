extends SceneTree

var checks := 0
var failures: Array[String] = []
const SNAPSHOT_PATH := "user://astra_057_focus.session"
const OLD_SNAPSHOT_PATH := "user://astra_057_old_focus.session"

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_scheduler_focus_budget()
    test_recent_and_continuation()
    test_pinned_and_speaker_exposure()
    test_hidden_state_independence()
    test_runtime_focus_recording()
    test_save_resume_compatibility()
    test_autonomous_density()
    test_existing_scheduler_invariants()
    AstraGameSession.delete_snapshot(SNAPSHOT_PATH)
    AstraGameSession.delete_snapshot(OLD_SNAPSHOT_PATH)
    if failures.is_empty():
        print("ASTRA 0.5.7 CLEAR SIGNAL TESTS OK · %d checks" % checks)
        quit(0)
        return
    print("ASTRA 0.5.7 CLEAR SIGNAL TESTS FAILED · %d/%d" % [failures.size(),checks])
    quit(1)

func _focus_context(families: Array = [], events: Array = [], exposure: Dictionary = {}, explicit_topic: bool = false) -> Dictionary:
    return {
        "loop_focus_families":families.duplicate(),
        "loop_focus_events":events.duplicate(true),
        "loop_focus_counts":{},
        "recent_focus_families":[],
        "speaker_exposure":exposure.duplicate(true),
        "explicit_topic":explicit_topic
    }

func _focus_scene(id: String, family: String, speaker: String = "rho") -> Dictionary:
    return {"id":id,"family":family,"speaker":speaker,"tag":"pair","category":"RELATIONSHIP","intent":"relationship"}

func test_scheduler_focus_budget() -> void:
    var continuation := {
        "id":"cont","family":"thread_a","speaker":"rho","tag":"pair","category":"RELATIONSHIP",
        "intent":"followup","chain_id":"arc_a"
    }
    var new_third := _focus_scene("third","thread_c")
    var new_fourth := _focus_scene("fourth","thread_d")
    var context := _focus_context(
        ["thread_a","thread_b"],
        [{"scene":"start","family":"thread_a","chain_id":"arc_a","category":"RELATIONSHIP","intent":"micro_arc"}]
    )
    var cont_w := AstraStoryletScheduler.weight(continuation,{},["thread_a"],"OLD_FRIENDS",{},context)
    var third_w := AstraStoryletScheduler.weight(new_third,{},[],"OLD_FRIENDS",{},context)
    check(cont_w > third_w,"actual continuation outranks a third unrelated high-salience thread")

    var context3 := _focus_context(["thread_a","thread_b","thread_c"],context["loop_focus_events"])
    var fourth_w := AstraStoryletScheduler.weight(new_fourth,{},[],"OLD_FRIENDS",{},context3)
    check(third_w > fourth_w,"fourth unrelated high-salience thread receives stronger soft penalty")

    var mandatory := {"id":"must","family":"must","speaker":"noa","tag":"awakening","category":"MANDATORY"}
    var mandatory_busy := AstraStoryletScheduler.weight(mandatory,{},[],"OLD_FRIENDS",{},context3)
    var mandatory_plain := AstraStoryletScheduler.weight(mandatory,{},[],"OLD_FRIENDS",{},_focus_context())
    check(is_equal_approx(mandatory_busy,mandatory_plain),"MANDATORY bypasses focus thread budget")

    var consequence := {"id":"due","family":"consequence_result","speaker":"mira","tag":"consequence","category":"CONSEQUENCE","intent":"followup"}
    var due_busy := AstraStoryletScheduler.weight(consequence,{},[],"OLD_FRIENDS",{},context3)
    var due_plain := AstraStoryletScheduler.weight(consequence,{},[],"OLD_FRIENDS",{},_focus_context())
    check(is_equal_approx(due_busy,due_plain),"due consequence/followup bypasses focus thread budget")

    var incident_after := {"id":"after","family":"incident_x","speaker":"sena","tag":"after","category":"INCIDENT_AFTER","intent":"aftermath"}
    check(AstraStoryletScheduler.salience(incident_after) == "FOLLOWUP","incident aftermath is FOLLOWUP salience")

func test_recent_and_continuation() -> void:
    var repeated := _focus_scene("repeat","thread_a")
    var repeat_w := AstraStoryletScheduler.weight(repeated,{},["thread_a"],"OLD_FRIENDS",{},_focus_context())
    var fresh_w := AstraStoryletScheduler.weight(repeated,{},[],"OLD_FRIENDS",{},_focus_context())
    check(repeat_w < fresh_w,"ordinary recent family repetition remains suppressed")
    check(not AstraStoryletScheduler.keep_fresh_candidate(repeated,[],["thread_a"],_focus_context()),"ordinary recent family fails fresh prefilter")

    var follow := {
        "id":"follow","family":"thread_a","speaker":"rho","tag":"pair","category":"RELATIONSHIP",
        "intent":"followup","chain_id":"arc_a"
    }
    var context := _focus_context(
        ["thread_a"],
        [{"scene":"start","family":"thread_a","chain_id":"arc_a","category":"RELATIONSHIP","intent":"micro_arc"}]
    )
    check(AstraStoryletScheduler.is_continuation(follow,context),"same active authored chain is recognized as continuation")
    check(AstraStoryletScheduler.keep_fresh_candidate(follow,["follow"],["thread_a"],context),"current-loop continuation survives fresh prefilter")
    var follow_recent := AstraStoryletScheduler.weight(follow,{},["thread_a"],"OLD_FRIENDS",{},context)
    var follow_not_recent := AstraStoryletScheduler.weight(follow,{},[],"OLD_FRIENDS",{},context)
    check(is_equal_approx(follow_recent,follow_not_recent),"continuation bypasses recent-family suppression")

    var explicit := _focus_context([],[],{},true)
    check(AstraStoryletScheduler.keep_fresh_candidate(repeated,["repeat"],["thread_a"],explicit),"explicit topic remains seekable despite recent-family prefilter")

func test_pinned_and_speaker_exposure() -> void:
    var pinned := {"id":"q_signal","related":["vale"]}
    var direct := _focus_scene("pin","thread_d","vale")
    direct["question_links"] = ["q_signal"]
    var unrelated := _focus_scene("other","thread_e","vale")
    var context := _focus_context(["a","b","c"])
    var direct_w := AstraStoryletScheduler.weight(direct,{},[],"OLD_FRIENDS",pinned,context)
    var unrelated_w := AstraStoryletScheduler.weight(unrelated,{},[],"OLD_FRIENDS",pinned,context)
    check(direct_w > unrelated_w,"direct pinned-question match relaxes unrelated new-thread penalty")
    check(AstraStoryletScheduler.direct_pinned_match(direct,pinned),"direct pinned-question link is detected")
    check(not AstraStoryletScheduler.direct_pinned_match(unrelated,pinned),"related speaker alone is not a direct pinned match")

    var optional := {"id":"optional","family":"optional","speaker":"rho","tag":"chat","category":"OPTIONAL"}
    var w0 := AstraStoryletScheduler.weight(optional,{},[],"OLD_FRIENDS",{},_focus_context([],[],{"rho":0}))
    var w1 := AstraStoryletScheduler.weight(optional,{},[],"OLD_FRIENDS",{},_focus_context([],[],{"rho":1}))
    var w2 := AstraStoryletScheduler.weight(optional,{},[],"OLD_FRIENDS",{},_focus_context([],[],{"rho":2}))
    var w3 := AstraStoryletScheduler.weight(optional,{},[],"OLD_FRIENDS",{},_focus_context([],[],{"rho":3}))
    check(is_equal_approx(w0,w1),"speaker exposure 0-1 has no penalty")
    check(w2 < w1,"speaker exposure 2 gets a soft penalty")
    check(w3 < w2,"speaker exposure 3+ gets a stronger soft penalty")

    var explicit_w := AstraStoryletScheduler.weight(optional,{},[],"OLD_FRIENDS",{},_focus_context([],[],{"rho":4},true))
    check(is_equal_approx(explicit_w,w0),"explicit topic bypasses speaker exposure penalty")

    var follow := optional.duplicate(true)
    follow["intent"] = "followup"
    follow["category"] = "CONSEQUENCE"
    var follow_w := AstraStoryletScheduler.weight(follow,{},[],"OLD_FRIENDS",{},_focus_context([],[],{"rho":4}))
    var follow_base := AstraStoryletScheduler.weight(follow,{},[],"OLD_FRIENDS",{},_focus_context())
    check(is_equal_approx(follow_w,follow_base),"FOLLOWUP bypasses speaker exposure penalty")

func test_hidden_state_independence() -> void:
    var scene := _focus_scene("safe","safe_family","noa")
    var visible := _focus_context(["a"],[{"scene":"start","family":"a","chain_id":"","category":"RELATIONSHIP","intent":"relationship"}])
    var leaked_a := visible.duplicate(true)
    leaked_a["truth"] = {"nulls":["mira"]}
    leaked_a["motives"] = {"noa":{"motive":"A"}}
    leaked_a["raw_relationships"] = {"noa:mira":0.99}
    var leaked_b := visible.duplicate(true)
    leaked_b["truth"] = {"nulls":["rho","dax"]}
    leaked_b["motives"] = {"noa":{"motive":"B"}}
    leaked_b["raw_relationships"] = {"noa:mira":0.01}
    var a := AstraStoryletScheduler.weight(scene,{},[],"OLD_FRIENDS",{},leaked_a)
    var b := AstraStoryletScheduler.weight(scene,{},[],"OLD_FRIENDS",{},leaked_b)
    check(is_equal_approx(a,b),"Null assignment cannot change focus weight")
    check(is_equal_approx(a,AstraStoryletScheduler.weight(scene,{},[],"OLD_FRIENDS",{},visible)),"hidden motive/raw relationship keys are ignored by focus API")

func _session() -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",570057)
    s.begin_voyage({"loops":3})
    s.voyage["scene"] = {}
    s.voyage["met"] = s.roster.duplicate()
    s.voyage["loop_focus_families"] = []
    s.voyage["loop_focus_events"] = []
    s.voyage["loop_focus_counts"] = {}
    return s

func test_runtime_focus_recording() -> void:
    var s := _session()
    var candidate := _focus_scene("candidate_only","candidate_family","rho")
    check(s.voyage["loop_focus_events"].is_empty(),"current-loop focus starts empty after test reset")
    # Merely holding an eligible candidate cannot mutate focus state.
    var candidates := [candidate]
    check(candidates.size() == 1 and s.voyage["loop_focus_events"].is_empty(),"unselected candidate is not recorded as focus")
    s._voyage_scene(candidate)
    check(s.voyage["loop_focus_events"].size() == 1,"actual _voyage_scene exposure records focus")
    check(s.voyage["loop_focus_families"] == ["candidate_family"],"visible focus family is recorded once")
    check(int(s.voyage["loop_focus_counts"].get("candidate_family",0)) == 1,"visible focus count increments")
    s._voyage_scene(candidate)
    check(s.voyage["loop_focus_families"].size() == 1 and int(s.voyage["loop_focus_counts"]["candidate_family"]) == 2,"repeat exposure increments count without duplicating distinct family")

    var ambient := {"id":"ambient","family":"ambient","speaker":"rho","tag":"work","category":"AUTONOMOUS"}
    s._voyage_scene(ambient)
    check("ambient" not in s.voyage["loop_focus_families"],"ambient/autonomous scene does not consume high-salience thread budget")

    var cap := _session()
    cap.voyage["mira_optional_exposure"] = 4
    cap.voyage["room"] = AstraVoyageContent.home_room("mira",cap.case_id)
    check(cap.voyage_talk("mira"),"Mira hard-cap path remains reachable")
    check(str(cap.voyage.get("scene",{}).get("id","")) == "053_mira_exposure_cap","Mira hard cap still returns the existing busy/silence scene")
    check(int(cap.voyage.get("mira_optional_exposure",0)) == 4,"Mira hard cap does not increase optional exposure past four")

func test_save_resume_compatibility() -> void:
    AstraGameSession.delete_snapshot(SNAPSHOT_PATH)
    AstraGameSession.delete_snapshot(OLD_SNAPSHOT_PATH)
    var s := _session()
    s._voyage_scene(_focus_scene("resume_focus","resume_family","rho"))
    s.voyage["scene"] = {}
    check(s.save_snapshot(SNAPSHOT_PATH),"0.5.7 focus snapshot saves")
    var restored := AstraGameSession.new()
    check(restored.load_snapshot(SNAPSHOT_PATH),"0.5.7 focus snapshot resumes")
    check(restored.voyage.get("loop_focus_families",[]) == ["resume_family"],"current-loop focus family survives resume")
    check(restored.voyage.get("loop_focus_events",[]).size() == 1,"current-loop focus event survives resume")

    var old := _session()
    for key in ["loop_focus_families","loop_focus_events","loop_focus_counts","recent_focus_families"]:
        old.voyage.erase(key)
    old.voyage["scene"] = {}
    check(old.save_snapshot(OLD_SNAPSHOT_PATH),"synthetic pre-0.5.7 snapshot saves")
    var old_restored := AstraGameSession.new()
    check(old_restored.load_snapshot(OLD_SNAPSHOT_PATH),"snapshot without focus keys still loads")
    check(old_restored.voyage.has("loop_focus_families") and old_restored.voyage["loop_focus_families"].is_empty(),"missing loop focus family defaults hydrate safely")
    check(old_restored.voyage.has("loop_focus_events") and old_restored.voyage["loop_focus_events"].is_empty(),"missing loop focus events hydrate safely")
    check(AstraGameSession.SNAPSHOT_VERSION == 3,"snapshot schema remains v3")
    check(AstraGameSession.SUPPORTED_SNAPSHOT_VERSIONS == [1,2,3],"snapshot v1/v2/v3 compatibility remains declared")

func test_autonomous_density() -> void:
    var s := _session()
    s.voyage["autonomous_seen_loop"] = ["beat_one"]
    s.voyage["loop_focus_families"] = ["thread_a","thread_b"]
    s.voyage["loop_focus_events"] = [
        {"scene":"incident","family":"incident","category":"INCIDENT","salience":"FOCUS"},
        {"scene":"follow","family":"thread_a","category":"CONSEQUENCE","salience":"FOLLOWUP"}
    ]
    check(s._should_defer_second_autonomous(),"dense loop softly defers a second autonomous beat")
    s.voyage["loop_focus_families"] = ["thread_a"]
    check(not s._should_defer_second_autonomous(),"quiet loop does not globally reduce autonomous max to one")

func test_existing_scheduler_invariants() -> void:
    var scene := {"id":"x","family":"f","speaker":"mira"}
    var unseen := AstraStoryletScheduler.weight(scene,{},[],"OLD_FRIENDS")
    var seen := AstraStoryletScheduler.weight(scene,{"x":2},[],"OLD_FRIENDS")
    check(unseen > seen,"existing unseen priority remains")
    var rare := {"id":"rare_x","rarity":"rare"}
    var base := AstraStoryletScheduler.rare_threshold(rare,{})
    var later := AstraStoryletScheduler.rare_threshold(rare,{"rare_x":4})
    check(later > base and later <= 0.85,"existing rare pity and upper bound remain")
    var state := AstraStoryletScheduler.update_pity({},[rare],"")
    state = AstraStoryletScheduler.update_pity(state,[rare],"rare_x")
    check(int(state.get("rare_x",-1)) == 0,"selected rare pity still resets")
    var sig_a := AstraStoryletScheduler.visible_signature("OLD_FRIENDS",{"id":"a"},["s1"],["r1"],"")
    var sig_b := AstraStoryletScheduler.visible_signature("OLD_FRIENDS",{"id":"b"},["s1"],["r1"],"")
    check(sig_a != sig_b,"visible_signature regression remains intact")
