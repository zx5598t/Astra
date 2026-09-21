extends SceneTree

# CLEAR SIGNAL runtime exposure gate. The simulation follows the public voyage
# path (begin -> move -> talk/pin/inspect -> autonomous/consequence/incident
# opportunities) and never forces a particular authored scene id.

const LOOPS := 500
const PROFILES := ["EXPLORER","LOYALIST","INVESTIGATOR","MINIMAL","SOCIAL"]
var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    simulate()
    if failures.is_empty():
        print("ASTRA 0.5.7 CLEAR SIGNAL SIMULATION OK · %d checks" % checks)
        quit(0)
    print("ASTRA 0.5.7 CLEAR SIGNAL SIMULATION FAILED · %d/%d" % [failures.size(),checks])
    quit(1)

func _close(s: AstraGameSession) -> void:
    s.voyage["scene"] = {}

func _percentile(values: Array, p: float) -> float:
    if values.is_empty():
        return 0.0
    var sorted := values.duplicate()
    sorted.sort()
    var index := clampi(int(ceil(p * float(sorted.size()))) - 1,0,sorted.size()-1)
    return float(sorted[index])

func _avg(values: Array) -> float:
    if values.is_empty():
        return 0.0
    var total := 0.0
    for value in values:
        total += float(value)
    return total / float(values.size())

func _profile_contacts(profile: String, s: AstraGameSession, run: int) -> Array:
    var order: Array = s.roster.duplicate()
    match profile:
        "LOYALIST":
            var favorite := str(order[run % order.size()])
            return [favorite,favorite,favorite,favorite]
        "INVESTIGATOR":
            var related: Array = s.pinned_question_entry().get("related",[])
            var contacts: Array = []
            for value in related:
                var who := str(value)
                if who in s.roster and who not in contacts:
                    contacts.append(who)
            for who in order:
                if contacts.size() >= 4:
                    break
                if who not in contacts:
                    contacts.append(who)
            return contacts.slice(0,4)
        "MINIMAL":
            return [str(order[run % order.size()]),str(order[(run + 3) % order.size()])]
        "SOCIAL":
            return [str(order[(run+i) % order.size()]) for i in range(6)]
        _:
            return [str(order[(run*3+i*2) % order.size()]) for i in range(4)]

func _visit_and_talk(s: AstraGameSession, who: String, explicit_topic: bool = false) -> void:
    if who not in s.active_participants():
        return
    var state: Dictionary = s.routine_state_for(who)
    var room := str(state.get("location",AstraVoyageContent.home_room(who,s.case_id)))
    if room not in s.voyage_rooms():
        room = AstraVoyageContent.home_room(who,s.case_id)
    if not s.voyage.get("scene",{}).is_empty():
        _close(s)
    if not s.voyage_move(room,true):
        return
    # Movement can naturally deliver a due consequence, incident, autonomous
    # beat, awakening, or another scheduled scene. Count it as seen and then
    # continue like a player closing that scene.
    if not s.voyage.get("scene",{}).is_empty():
        _close(s)
    if who not in s.voyage_people():
        return
    if who not in s.voyage.get("met",[]):
        # A first meeting is naturally an awakening scene; use the same public
        # visit path, close it, and only then attempt optional conversation.
        if s.voyage_visit_person(who):
            _close(s)
    if who in s.voyage.get("met",[]) and s.voyage.get("scene",{}).is_empty():
        var topic := ""
        if explicit_topic:
            # Use a currently eligible visible tag rather than manufacturing a
            # special scene id. If no topic is found the ordinary selector runs.
            for candidate in AstraVoyageContent.all_scenes():
                if str(candidate.get("speaker","")) == who and s._scene_eligible_052(candidate,who):
                    var tag := str(candidate.get("tag",""))
                    if tag != "awakening":
                        topic = tag
                        break
        if s.voyage_talk(who,topic):
            _close(s)

func _try_inspection(s: AstraGameSession) -> void:
    if not s.voyage.get("scene",{}).is_empty():
        _close(s)
    var points := s.voyage_points()
    if points.is_empty():
        return
    var point_id := str(points[0][0])
    if s.voyage_inspect(point_id):
        if not s.voyage.get("scene",{}).is_empty():
            _close(s)

func _unrelated_and_continuations(events: Array) -> Dictionary:
    var context := {
        "loop_focus_families":[],
        "loop_focus_events":[],
        "loop_focus_counts":{},
        "recent_focus_families":[],
        "speaker_exposure":{},
        "explicit_topic":false
    }
    var unrelated := 0
    var continuations := 0
    for raw in events:
        var event: Dictionary = raw
        var synthetic := {
            "id":str(event.get("scene","")),
            "family":str(event.get("family","")),
            "chain_id":str(event.get("chain_id","")),
            "category":str(event.get("category","")),
            "intent":str(event.get("intent","")),
            "tag":str(event.get("tag","")),
            "speaker":str(event.get("speaker",""))
        }
        var level := str(event.get("salience",""))
        var continuation := AstraStoryletScheduler.is_continuation(synthetic,context)
        if continuation:
            continuations += 1
        elif level in ["FOCUS","FOLLOWUP"]:
            var family := str(event.get("family",""))
            if family != "" and family not in context["loop_focus_families"]:
                unrelated += 1
        var family := str(event.get("family",""))
        if level in ["FOCUS","FOLLOWUP"] and family != "" and family not in context["loop_focus_families"]:
            context["loop_focus_families"].append(family)
        context["loop_focus_events"].append(event)
    return {"unrelated":unrelated,"continuations":continuations}

func simulate() -> void:
    var memory := {"loops":0}
    var optional_counts: Array = []
    var distinct_counts: Array = []
    var unrelated_counts: Array = []
    var autonomous_counts: Array = []
    var continuation_total := 0
    var meaningful_event_total := 0
    var loops_four_plus := 0
    var zero_meaningful := 0
    var consecutive_zero := 0
    var max_consecutive_zero := 0
    var incident_loops := 0
    var consequence_loops := 0
    var signatures := {}
    var autonomous_unique := {}
    var scene_hits := {}
    var pair_hits := {}
    var rare_immediate_repeats := 0
    var previous_rares: Array = []
    var adjacent_focus_repeats := 0
    var previous_focus: Array = []
    var character_values := {}
    var character_focus_loops := {}
    var profile_stats := {}
    for who in AstraCrewCatalog.ORDER:
        character_values[who] = []
        character_focus_loops[who] = 0
    for profile in PROFILES:
        profile_stats[profile] = {"loops":0,"distinct":[],"unrelated":[],"optional":[],"continuations":0}

    for run in range(LOOPS):
        var profile := str(PROFILES[run % PROFILES.size()])
        var s := AstraGameSession.new()
        s.setup("LAST_LIGHT",1570000 + run * 101,"ANALYST","STANDARD")
        s.begin_voyage(memory)
        _close(s)

        if profile == "INVESTIGATOR":
            var questions := s.current_questions()
            if not questions.is_empty():
                s.pin_question(str(questions[0].get("id","")))

        # An actual inspection keeps MINIMAL from becoming a synthetic talk-only
        # profile and naturally advances ticks, incidents and due consequences.
        if profile in ["MINIMAL","INVESTIGATOR"]:
            _try_inspection(s)

        var contacts := _profile_contacts(profile,s,run)
        for i in range(contacts.size()):
            _visit_and_talk(s,str(contacts[i]),profile == "LOYALIST" and i == contacts.size()-1)

        # Give a queued autonomous beat one natural room opportunity. A SOCIAL
        # loop may attempt a second one; CLEAR SIGNAL can leave it queued when
        # the loop is already dense.
        var queue: Array = s.voyage.get("activity_queue",[])
        if not queue.is_empty():
            var room := str(queue[0].get("room",""))
            if s.voyage.get("scene",{}).is_empty():
                s.voyage_move(room,false)
            if s.voyage.get("scene",{}).is_empty() and s._maybe_autonomous_beat(room):
                _close(s)
            if profile == "SOCIAL":
                queue = s.voyage.get("activity_queue",[])
                if not queue.is_empty():
                    var room2 := str(queue[0].get("room",""))
                    if s.voyage.get("scene",{}).is_empty():
                        s.voyage_move(room2,false)
                    if s.voyage.get("scene",{}).is_empty() and s._maybe_autonomous_beat(room2):
                        _close(s)

        var events: Array = s.voyage.get("loop_focus_events",[]).duplicate(true)
        var thread_stats := _unrelated_and_continuations(events)
        var distinct := int(s.voyage.get("loop_focus_families",[]).size())
        var unrelated := int(thread_stats["unrelated"])
        var continuations := int(thread_stats["continuations"])
        var optional_total := 0
        for value in s.voyage.get("speaker_exposure",{}).values():
            optional_total += int(value)
        optional_counts.append(optional_total)
        distinct_counts.append(distinct)
        unrelated_counts.append(unrelated)
        continuation_total += continuations
        meaningful_event_total += events.size()
        if unrelated >= 4:
            loops_four_plus += 1
        if distinct == 0:
            zero_meaningful += 1
            consecutive_zero += 1
            max_consecutive_zero = maxi(max_consecutive_zero,consecutive_zero)
        else:
            consecutive_zero = 0

        var has_incident := false
        var has_consequence := false
        var focused_speakers := {}
        for event_raw in events:
            var event: Dictionary = event_raw
            var category := str(event.get("category",""))
            if category in ["INCIDENT","INCIDENT_AFTER"]:
                has_incident = true
            if category == "CONSEQUENCE":
                has_consequence = true
            var speaker := str(event.get("speaker",""))
            if speaker in AstraCrewCatalog.ORDER:
                focused_speakers[speaker] = true
        if has_incident: incident_loops += 1
        if has_consequence: consequence_loops += 1
        for who in focused_speakers:
            character_focus_loops[who] = int(character_focus_loops.get(who,0)) + 1

        var focus_now: Array = s.voyage.get("loop_focus_families",[])
        for family in focus_now:
            if str(family) in previous_focus:
                adjacent_focus_repeats += 1
        previous_focus = focus_now.duplicate()

        var exposure: Dictionary = s.voyage.get("speaker_exposure",{})
        for who in AstraCrewCatalog.ORDER:
            character_values[who].append(int(exposure.get(who,0)))

        var autos: Array = s.voyage.get("autonomous_seen_loop",[])
        autonomous_counts.append(autos.size())
        for beat in autos:
            autonomous_unique[str(beat)] = true

        for id in s.voyage.get("visible_scene_ids",[]):
            scene_hits[str(id)] = true
        for event_raw in events:
            var event: Dictionary = event_raw
            var family := str(event.get("family",""))
            if ":" in family or "_" in family:
                var speaker := str(event.get("speaker",""))
                if speaker != "":
                    pair_hits[speaker + "|" + family] = true

        var current_rares: Array = s.voyage.get("visible_rare_ids",[]).duplicate()
        for rare in current_rares:
            if rare in previous_rares:
                rare_immediate_repeats += 1
        previous_rares = current_rares

        var signature := AstraStoryletScheduler.visible_signature(
            str(s.voyage.get("social_theme","")),
            s.voyage.get("loop_hook",{}),
            Array(s.voyage.get("visible_scene_ids",[])).slice(0,5),
            current_rares.slice(0,2),
            ",".join(PackedStringArray(focus_now.map(func(x): return str(x))))
        )
        signatures[signature] = true

        var ps: Dictionary = profile_stats[profile]
        ps["loops"] = int(ps["loops"]) + 1
        ps["distinct"].append(distinct)
        ps["unrelated"].append(unrelated)
        ps["optional"].append(optional_total)
        ps["continuations"] = int(ps["continuations"]) + continuations
        profile_stats[profile] = ps
        memory = s.voyage_memory()

    var total_053 := AstraStorylets053.scenes().size()
    var seen_053 := 0
    for scene in AstraStorylets053.scenes():
        if scene_hits.has(str(scene.get("id",""))):
            seen_053 += 1
    var coverage := float(seen_053) / maxf(1.0,float(total_053))
    var continuation_ratio := float(continuation_total) / maxf(1.0,float(meaningful_event_total))

    print("CLEAR SIGNAL 500 LOOPS")
    print("  optional authored scenes avg=%.2f p95=%.0f max=%d" % [_avg(optional_counts),_percentile(optional_counts,0.95),int(optional_counts.max())])
    print("  high-salience distinct families avg=%.2f p95=%.0f max=%d" % [_avg(distinct_counts),_percentile(distinct_counts,0.95),int(distinct_counts.max())])
    print("  continuation count=%d ratio=%.3f" % [continuation_total,continuation_ratio])
    print("  unrelated new-thread avg=%.2f p95=%.0f max=%d · loops 4+=%d" % [_avg(unrelated_counts),_percentile(unrelated_counts,0.95),int(unrelated_counts.max()),loops_four_plus])
    print("  zero-meaningful=%d · max consecutive=%d · adjacent focus repeats=%d" % [zero_meaningful,max_consecutive_zero,adjacent_focus_repeats])
    print("  autonomous avg=%.2f max=%d unique=%d · incident loops=%d · consequence loops=%d" % [_avg(autonomous_counts),int(autonomous_counts.max()),autonomous_unique.size(),incident_loops,consequence_loops])
    print("  visible signatures=%d · 0.5.3 authored coverage=%.1f%% · pair/focus samples=%d · rare immediate repeats=%d" % [signatures.size(),coverage*100.0,pair_hits.size(),rare_immediate_repeats])
    for who in AstraCrewCatalog.ORDER:
        var values: Array = character_values[who]
        print("  %s optional avg=%.2f p95=%.0f max=%d · focus loops=%d" % [who,_avg(values),_percentile(values,0.95),int(values.max()),int(character_focus_loops[who])])
    for profile in PROFILES:
        var ps: Dictionary = profile_stats[profile]
        print("  %s loops=%d distinct avg=%.2f p95=%.0f unrelated avg=%.2f optional avg=%.2f continuations=%d" % [
            profile,int(ps["loops"]),_avg(ps["distinct"]),_percentile(ps["distinct"],0.95),
            _avg(ps["unrelated"]),_avg(ps["optional"]),int(ps["continuations"])
        ])

    # Release gates. Mandatory/due events do not consume loop_focus_families,
    # so these directly measure the soft high-salience budget.
    check(_avg(distinct_counts) >= 1.5 and _avg(distinct_counts) <= 3.2,"ordinary loop high-salience distinct-family average stays focused (%.2f)" % _avg(distinct_counts))
    check(_percentile(distinct_counts,0.95) <= 4.0,"high-salience distinct-family p95 stays <= 4 (%.0f)" % _percentile(distinct_counts,0.95))
    check(loops_four_plus <= 25,"4+ unrelated high-salience threads remain exceptional (%d/500)" % loops_four_plus)
    check(max_consecutive_zero <= 1,"zero-meaningful loops do not occur consecutively (max %d)" % max_consecutive_zero)
    check(continuation_total > 0,"visible high-salience continuations occur in runtime")
    check(signatures.size() >= 150,"existing visible signature variety remains high (%d)" % signatures.size())
    check(autonomous_unique.size() >= 12,"autonomous unique coverage remains at HEARTBEAT gate (%d)" % autonomous_unique.size())
    check(coverage >= 0.55,"0.5.3 authored coverage remains >= 55%% (%.1f%%)" % (coverage*100.0))
    check(rare_immediate_repeats <= 8,"rare immediate repeat gate remains <= 8 (%d)" % rare_immediate_repeats)
    check(int(Array(character_values["mira"]).max()) <= 4,"Mira optional exposure max remains <= 4 (%d)" % int(Array(character_values["mira"]).max()))
