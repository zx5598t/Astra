extends SceneTree

# Player-visible replay audit for ASTRA 0.5.3.
# This complements the 0.5.2 structural signature simulation: it records what
# a player could actually notice — hook, authored 0.5.3 scenes, rare moments
# and autonomous crew activity.

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    simulate_visible_loops()
    if failures.is_empty():
        print("ASTRA 0.5.3 HEARTBEAT SIMULATION OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.3 HEARTBEAT SIMULATION FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func _close(s: AstraGameSession) -> void:
    s.voyage["scene"] = {}

func simulate_visible_loops() -> void:
    var memory := {"loops":0}
    var signatures := {}
    var scene_hits := {}
    var autonomous_hits := {}
    var pair_hits := {}
    var mira_total_exposure := 0
    var mira_max_exposure := 0
    var rare_immediate_repeats := 0
    var previous_rares: Array = []
    var summaries: Array[String] = []

    for run in range(500):
        var s := AstraGameSession.new()
        s.setup("LAST_LIGHT",1530000 + run * 83,"ANALYST","STANDARD")
        s.begin_voyage(memory)
        _close(s)
        s.voyage["met"] = s.roster.duplicate()
        s.voyage["actions"] = 8

        # Vary how much the simulated player seeks Mira. This measures the
        # actual selector/cap instead of forcing four Mira scenes every loop.
        var mira_talks := 1 + (run % 4)
        s.voyage["room"] = AstraVoyageContent.home_room("mira",s.case_id)
        for i in range(mira_talks):
            if s.voyage_talk("mira"):
                var selected: Dictionary = s.voyage.get("scene",{})
                var id := str(selected.get("id",""))
                if id != "":
                    scene_hits[id] = int(scene_hits.get(id,0)) + 1
                var target := str(selected.get("target",""))
                if target != "":
                    pair_hits[AstraCrewCatalog.pair_key("mira",target)] = true
                _close(s)

        # Give every other crew member one optional contact, but do not force
        # every event type or every room in a single run.
        for npc_id in s.roster:
            var who := str(npc_id)
            if who == "mira":
                continue
            s.voyage["room"] = AstraVoyageContent.home_room(who,s.case_id)
            if s.voyage_talk(who):
                var selected: Dictionary = s.voyage.get("scene",{})
                var id := str(selected.get("id",""))
                if id != "":
                    scene_hits[id] = int(scene_hits.get(id,0)) + 1
                var target := str(selected.get("target",""))
                if target != "":
                    pair_hits[AstraCrewCatalog.pair_key(who,target)] = true
                _close(s)

        # Observe at most one naturally scheduled autonomous beat.
        var queue: Array = s.voyage.get("activity_queue",[])
        if not queue.is_empty():
            var room := str(queue[0].get("room",""))
            s.voyage["room"] = room
            if s._maybe_autonomous_beat(room):
                var beat_id := str(s.voyage.get("scene",{}).get("id",""))
                if beat_id != "":
                    autonomous_hits[beat_id] = int(autonomous_hits.get(beat_id,0)) + 1
                _close(s)

        var exposure := int(s.voyage.get("mira_optional_exposure",0))
        mira_total_exposure += exposure
        mira_max_exposure = maxi(mira_max_exposure,exposure)
        var current_rares: Array = s.voyage.get("visible_rare_ids",[]).duplicate()
        for rare_id in current_rares:
            if rare_id in previous_rares:
                rare_immediate_repeats += 1
        previous_rares = current_rares

        var signature := AstraStoryletScheduler.visible_signature(
            str(s.voyage.get("social_theme","")),
            s.voyage.get("loop_hook",{}),
            Array(s.voyage.get("visible_scene_ids",[])).slice(0,5),
            current_rares.slice(0,2),
            ""
        )
        signatures[signature] = int(signatures.get(signature,0)) + 1

        if run < 5:
            summaries.append("LOOP %d · theme=%s · hook=%s · scenes=%s · rare=%s · Mira=%d · autonomous=%s" % [
                run + 1,
                str(s.voyage.get("social_theme","")),
                str(s.voyage.get("loop_hook",{}).get("id","")),
                str(Array(s.voyage.get("visible_scene_ids",[])).slice(0,4)),
                str(current_rares.slice(0,2)),
                exposure,
                str(Array(s.voyage.get("autonomous_seen_loop",[])).slice(0,1))
            ])
        memory = s.voyage_memory()

    var total_053 := AstraStorylets053.scenes().size()
    var seen_053 := 0
    for scene in AstraStorylets053.scenes():
        if scene_hits.has(str(scene.get("id",""))):
            seen_053 += 1
    var coverage := float(seen_053) / maxf(1.0,float(total_053))
    var mira_avg := float(mira_total_exposure) / 500.0

    check(mira_max_exposure <= 4,"Mira optional exposure never exceeds the loop cap (%d)" % mira_max_exposure)
    check(mira_avg >= 1.0 and mira_avg <= 3.2,"Mira remains present without swallowing the optional loop (avg %.2f)" % mira_avg)
    check(signatures.size() >= 150,"player-visible replay signatures vary substantially (%d/500)" % signatures.size())
    check(autonomous_hits.size() >= 12,"500 loops expose a broad autonomous library (%d unique)" % autonomous_hits.size())
    check(pair_hits.size() >= 8,"optional play reaches multiple relationship pairs (%d)" % pair_hits.size())
    check(coverage >= 0.55,"500 loops cover a majority of 0.5.3 authored material (%.1f%%)" % (coverage * 100.0))
    check(rare_immediate_repeats <= 8,"rare moments do not repeat immediately at a noticeable rate (%d)" % rare_immediate_repeats)

    print("HEARTBEAT 500 LOOPS · visible_signatures=%d · Mira avg=%.2f max=%d · autonomous=%d · pair_coverage=%d · 0.5.3 scene coverage=%.1f%% · rare_immediate_repeats=%d" % [
        signatures.size(),mira_avg,mira_max_exposure,autonomous_hits.size(),pair_hits.size(),coverage*100.0,rare_immediate_repeats
    ])
    print("FIVE LOOP HUMAN-READABLE SAMPLE")
    for summary in summaries:
        print("  " + summary)
