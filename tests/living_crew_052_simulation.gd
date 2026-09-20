extends SceneTree

# ASTRA 0.5.2 scale simulations.
# 1,000 runtime conversations, 1,000 generated meetings, 500 full loop selectors.

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    simulate_conversations()
    simulate_meetings()
    simulate_loops()
    if failures.is_empty():
        print("ASTRA 0.5.2 SIMULATION OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.2 SIMULATION FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func simulate_conversations() -> void:
    var samples := 0
    var bad_topic := 0
    var empty_answers := 0
    var intents := ["ALIBI","WITNESS","TIMELINE","TRUST"]
    # LAST_LIGHT has all eight crew. 125 sessions × 8 people = 1,000 real asks.
    for run in range(125):
        var s := AstraGameSession.new()
        s.setup("LAST_LIGHT",810000 + run * 37,"ANALYST","STANDARD")
        s.phase = "INTERROGATION"
        s.talk_ap = 32
        s.pending_event.clear()
        var roster := s.living_ids()
        for index in range(roster.size()):
            var who := str(roster[index])
            var intent := str(intents[(run + index) % intents.size()])
            var result := s.ask(who,intent)
            samples += 1
            if not bool(result.get("ok",false)) or str(result.get("response_family","")) != intent:
                bad_topic += 1
                continue
            if Array(result.get("lines",[])).is_empty():
                empty_answers += 1
            for line in result.get("lines",[]):
                if str(line.get("intent",intent)) != intent:
                    bad_topic += 1
    check(samples == 1000,"conversation simulation produced exactly 1,000 samples")
    check(bad_topic == 0,"1,000 conversations stay on the question topic (bad=%d)" % bad_topic)
    check(empty_answers == 0,"1,000 conversations produce an actual response (empty=%d)" % empty_answers)
    print("CONVERSATION COHERENCE · samples=%d · topic_errors=%d · empty=%d" % [samples,bad_topic,empty_answers])

func simulate_meetings() -> void:
    var meetings := 0
    var entries := 0
    var replies := 0
    var bad_reply := 0
    var bad_speaker := 0
    var bad_type := 0
    # Reuse each generated case across four days: 250 cases × 4 = 1,000 meetings.
    for run in range(250):
        var s := AstraGameSession.new()
        s.setup("LAST_LIGHT",910000 + run * 53,"ANALYST","STANDARD")
        for meeting_day in range(1,5):
            s.day = meeting_day
            s.phase = "MEETING"
            s._open_meeting()
            meetings += 1
            var seen := {}
            for entry in s.meeting_feed:
                entries += 1
                var speaker := str(entry.get("speaker",""))
                if speaker != "player" and not s.can_meeting_speak(speaker):
                    bad_speaker += 1
                if str(entry.get("thread_type","")) not in ["FACT_THREAD","RELATION_THREAD","DECISION_THREAD"]:
                    bad_type += 1
                var reply_to := str(entry.get("reply_to",""))
                if reply_to != "":
                    replies += 1
                    if not seen.has(reply_to) or str(seen[reply_to].get("topic","")) != str(entry.get("topic","")):
                        bad_reply += 1
                seen[str(entry.get("entry_id",""))] = entry
    check(meetings == 1000,"meeting simulation produced exactly 1,000 meetings")
    check(entries >= 1000,"meeting simulation contains visible authored reactions (%d entries)" % entries)
    check(replies > 0 and bad_reply == 0,"meeting replies always point to earlier context on the same topic")
    check(bad_speaker == 0,"1,000 meetings never use inactive speakers")
    check(bad_type == 0,"every meeting entry belongs to FACT/RELATION/DECISION thread")
    print("MEETING COHERENCE · meetings=%d · entries=%d · replies=%d · bad_reply=%d · bad_speaker=%d" % [meetings,entries,replies,bad_reply,bad_speaker])

func simulate_loops() -> void:
    var signatures := {}
    var scene_hits := {}
    var rare_hits := {}
    var themes := {}
    var previous_memory := {"loops":0}
    var previous_signature := ""
    var consecutive_duplicates := 0
    for run in range(500):
        # Carry the memory forward every few runs so this also exercises the
        # "meet the same people again" state, not 500 isolated fresh games.
        if run % 7 == 0:
            previous_memory = {"loops":run % 6}
        var s := AstraGameSession.new()
        s.setup("LAST_LIGHT",1010000 + run * 71,"ANALYST","STANDARD")
        s.begin_voyage(previous_memory)
        s.voyage["scene"] = {}
        s.voyage["met"] = s.roster.duplicate()
        s.voyage["hook_shown"] = true
        var past_parts: Array[String] = []
        for key in s.voyage.get("past",{}).keys():
            past_parts.append(str(key) + "=" + str(s.voyage["past"][key].get("type","")))
        past_parts.sort()
        var signature := "%s|%s" % [str(s.voyage.get("social_theme","")),",".join(past_parts)]
        signatures[signature] = int(signatures.get(signature,0)) + 1
        themes[str(s.voyage.get("social_theme",""))] = true
        if signature == previous_signature:
            consecutive_duplicates += 1
        previous_signature = signature
        for npc_id in s.roster:
            var who := str(npc_id)
            s.voyage["scene"] = {}
            s.voyage["room"] = AstraVoyageContent.home_room(who,s.case_id)
            if s.voyage_talk(who):
                var picked: Dictionary = s.voyage.get("scene",{})
                var id := str(picked.get("id",""))
                if id != "":
                    scene_hits[id] = int(scene_hits.get(id,0)) + 1
                    if str(picked.get("rarity","")) == "rare":
                        rare_hits[id] = true
        previous_memory = s.voyage_memory()
    var added := AstraStorylets052.scenes()
    var added_seen := 0
    for scene in added:
        if scene_hits.has(str(scene.get("id",""))):
            added_seen += 1
    var coverage := float(added_seen) / maxf(1.0,float(added.size()))
    check(signatures.size() >= 60,"500 loops produce many social signatures (%d)" % signatures.size())
    check(themes.size() >= 5,"500 loops exercise most social themes (%d)" % themes.size())
    check(consecutive_duplicates <= 15,"near-identical consecutive loop signatures stay rare (%d/499)" % consecutive_duplicates)
    check(coverage >= 0.40,"500-loop authored 0.5.2 scene coverage is meaningful (%.1f%%)" % (coverage * 100.0))
    check(rare_hits.size() >= 4,"rare protection actually exposes multiple rare scenes (%d)" % rare_hits.size())
    print("500 LOOP DIVERSITY · signatures=%d · themes=%d · consecutive_duplicates=%d · 0.5.2 scene coverage=%.1f%% · rare_seen=%d" % [signatures.size(),themes.size(),consecutive_duplicates,coverage*100.0,rare_hits.size()])
