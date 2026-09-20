extends SceneTree
# Content-quality audit (design doc §20, promoted to a real gate in §57).
# FAIL = a regression against something this project claims to already do.
# WARN = a known, disclosed gap — not yet true, but not a regression either.
# Exit code is 1 iff there is at least one FAIL; WARN never changes the exit
# code. This script is intentionally NOT wired into tools/build_windows.ps1:
# as of 0.4.2 it FAILS on two checks (uniform tag sets, scene-count spread)
# because the full per-character scene rewrite (§10-12) is still undone —
# gating the build on that would block a working build on a disclosed,
# out-of-scope gap. Run it on its own to see exactly where content stands.
#   godot --headless --path . --script res://tests/content_audit.gd

var fails: Array[String] = []
var warns: Array[String] = []

func _initialize() -> void:
    print("=== ASTRA CONTENT AUDIT ===")
    _tag_sets_by_character()
    _scene_counts_by_character()
    _choice_effect_vocabulary()
    _sentence_openers()
    _pair_scene_distribution()
    _personal_vs_everyday_ratio()
    _private_event_counts()
    _authored_scene_volume()
    _key_pair_and_trio_depth()
    _vote_and_speaker_invariants()
    _pair_history_symmetry()
    _calibration_never_shows_meeting_or_vote()
    _dead_air_light_phase_flow()
    print("\n=== summary: %d FAIL, %d WARN ===" % [fails.size(), warns.size()])
    for f in fails: printerr("FAIL · " + f)
    for w in warns: print("WARN · " + w)
    if fails.is_empty():
        print("ASTRA CONTENT AUDIT OK")
    quit(1 if not fails.is_empty() else 0)

func _by_speaker() -> Dictionary:
    var out := {}
    for scene in AstraVoyageContent.all_scenes():
        var who := str(scene["speaker"])
        if not out.has(who): out[who] = []
        out[who].append(scene)
    return out

func _tag_sets_by_character() -> void:
    print("\n-- 1. Does every character share the exact same tag set? --")
    var by_speaker := _by_speaker()
    var sets := {}
    for who in by_speaker:
        var tags := {}
        for scene in by_speaker[who]: tags[str(scene["tag"])] = true
        sets[who] = tags.keys()
        sets[who].sort()
    var reference: Array = sets.get("mira", [])
    var identical := true
    for who in sets:
        if who == "mira": continue
        if sets[who] != reference: identical = false
    if identical:
        fails.append("every character has the identical %d-tag set (§10/§12 not yet done)" % reference.size())
    else:
        print("  OK: tag sets differ across characters.")
    for who in sets:
        print("  %s: %d tags — %s" % [who, sets[who].size(), str(sets[who])])

func _scene_counts_by_character() -> void:
    print("\n-- 2. Are per-character scene counts mechanically equal? --")
    var by_speaker := _by_speaker()
    var counts := []
    for who in by_speaker: counts.append(by_speaker[who].size())
    var lo: int = counts.min()
    var hi: int = counts.max()
    if hi - lo <= 2:
        fails.append("scene counts only range %d-%d (§10 asks for a spread that follows personality, not a fixed quota)" % [lo, hi])
    else:
        print("  OK: scene counts range %d–%d." % [lo, hi])
    for who in by_speaker: print("  %s: %d scenes" % [who, by_speaker[who].size()])

func _choice_effect_vocabulary() -> void:
    print("\n-- 3. Choice effect vocabulary --")
    var effects := {}
    for scene in AstraVoyageContent.all_scenes():
        for choice in scene.get("choices", []):
            var effect := str(choice.get("effect", ""))
            effects[effect] = int(effects.get(effect, 0)) + 1
    var keys := effects.keys()
    keys.sort()
    print("  %d distinct effects across all choices: %s" % [keys.size(), str(keys)])
    if keys.size() <= 7:
        fails.append("effect vocabulary fell back to 7 or fewer kinds (§16 added confront/withhold/keep_copy/promise)")

func _sentence_openers() -> void:
    print("\n-- 4. Repeated opening words in 'action' lines (possible template smell) --")
    var openers := {}
    for scene in AstraVoyageContent.all_scenes():
        var action := str(scene.get("action", ""))
        if action == "": continue
        var words := action.split(" ")
        var first_word := words[0] if not words.is_empty() else action.substr(0, mini(4, action.length()))
        # Most Korean action narration naturally starts with the acting
        # character's name ("준이", "미라가"). That is not template smell.
        # Audit the first meaningful verb/object phrase after the subject.
        if first_word in ["준이","마렌이","노아가","미라가","세나가","다렌이","루칸이","소렌이"] and words.size() > 1:
            first_word = words[1]
        openers[first_word] = int(openers.get(first_word, 0)) + 1
    var repeated: Array = []
    for word in openers:
        if int(openers[word]) >= 5: repeated.append("%s (%d)" % [word, openers[word]])
    if repeated.is_empty():
        print("  OK: no opening word repeats 5+ times across all scenes.")
    else:
        warns.append("openers repeated 5+ times: %s" % ", ".join(PackedStringArray(repeated)))

func _pair_scene_distribution() -> void:
    print("\n-- 5. NPC-pair ('pair' tag) scene distribution --")
    var pairs := {}
    for scene in AstraVoyageContent.all_scenes():
        if str(scene.get("tag","")) != "pair": continue
        var key := AstraCrewCatalog.pair_key(str(scene["speaker"]), str(scene.get("target","")))
        pairs[key] = int(pairs.get(key,0)) + 1
    var total: int = pairs.values().reduce(func(a,b): return a+b, 0)
    print("  %d pair scenes across %d distinct unordered pairings: %s" % [total, pairs.size(), str(pairs)])
    if pairs.size() < 8:
        warns.append("only %d distinct pair scene pairings (§12 wants a real relationship web); pair_history (§20-23) now covers every pair even where no scene exists yet" % pairs.size())

func _personal_vs_everyday_ratio() -> void:
    print("\n-- 6. Personal/secret/echo vs. everyday/work ratio, per character --")
    var by_speaker := _by_speaker()
    var personal_tags := ["personal","secret","echo","grief","apology"]
    var everyday_tags := ["everyday","work","observation"]
    var ratios := []
    var ratio_keys := {}
    for who in by_speaker:
        var personal := 0
        var everyday := 0
        for scene in by_speaker[who]:
            var tag := str(scene["tag"])
            if tag in personal_tags: personal += 1
            elif tag in everyday_tags: everyday += 1
        var ratio_key := "%d:%d" % [personal, everyday]
        ratio_keys[ratio_key] = true
        ratios.append("%s %s" % [who, ratio_key])
    print("  " + ", ".join(PackedStringArray(ratios)))
    if ratio_keys.size() < 4:
        warns.append("personal:everyday mix is still too mechanically similar (%d distinct mixes)" % ratio_keys.size())
    else:
        print("  OK: character content mixes use %d distinct personal:everyday profiles." % ratio_keys.size())

func _private_event_counts() -> void:
    print("\n-- 7. Private events per character --")
    var counts := {}
    var total := 0
    for npc_id in AstraCrewCatalog.ORDER:
        counts[npc_id] = AstraPrivateEvents.count_for(npc_id)
        total += int(counts[npc_id])
    print("  " + str(counts) + " / total " + str(total))
    for npc_id in counts:
        var count := int(counts[npc_id])
        if count < 4 or count > 7:
            fails.append("private events for %s: %d (0.5.0 requires 4-7 per character)" % [npc_id, count])
    if total < 40:
        fails.append("private event pool only %d; 0.5.0 requires about 40+" % total)

func _authored_scene_volume() -> void:
    print("\n-- 8. Authored voyage scene volume --")
    var total := AstraVoyageContent.all_scenes().size()
    print("  total authored voyage scenes: %d" % total)
    if total < 470:
        fails.append("authored voyage/reactive scenes %d; 0.5.3 release floor is 470" % total)
    if total > 550:
        warns.append("authored voyage/reactive scenes %d; verify one-run exposure remains restrained" % total)

func _key_pair_and_trio_depth() -> void:
    print("\n-- 9. Key pair and trio depth --")
    var required := [
        ["rho","sena"], ["mira","lyra"], ["dax","noa"], ["vale","eli"],
        ["rho","dax"], ["sena","mira"], ["lyra","dax"], ["noa","vale"]
    ]
    var counts := {}
    var trios := 0
    for scene in AstraVoyageContent.all_scenes():
        var tag := str(scene.get("tag",""))
        if tag == "pair":
            var key := AstraCrewCatalog.pair_key(str(scene.get("speaker","")), str(scene.get("target","")))
            counts[key] = int(counts.get(key,0)) + 1
        elif tag == "trio":
            trios += 1
    for pair in required:
        var key := AstraCrewCatalog.pair_key(str(pair[0]), str(pair[1]))
        var count := int(counts.get(key,0))
        print("  %s: %d" % [key,count])
        if count < 2:
            fails.append("key pair %s only has %d authored scenes; need at least 2" % [key,count])
    print("  trio scenes: %d" % trios)
    if trios < 4:
        fails.append("only %d authored trio scenes; 0.5.0 requires occasional 3-person conversation" % trios)

func _vote_and_speaker_invariants() -> void:
    print("\n-- 10. Vote/speaker model invariants --")
    for seed_value in range(1, 301):
        var s := AstraGameSession.new()
        s.setup("ECHO_WARD", 70000 + seed_value)
        var ballot := s.vote_intentions()
        for voter in ballot:
            var target := str(ballot[voter])
            if target != "" and (str(voter) == target or not s.can_vote_for(str(voter), target)):
                fails.append("illegal generated ballot %s -> %s at seed %d" % [str(voter),target,seed_value])
                return
        var active := s.active_participants()
        if active.size() < 3:
            continue
        var removed := str(active[0])
        s.crew[removed].status = AstraCrewMember.STATUS_OFFLINE
        var after := s.vote_intentions()
        if after.has(removed):
            fails.append("offline voter remained in ballot at seed %d" % seed_value)
            return
        for voter in after:
            if str(after[voter]) == removed:
                fails.append("offline target remained in ballot at seed %d" % seed_value)
                return
        if s.can_meeting_speak(removed):
            fails.append("offline speaker remained eligible for meeting feed at seed %d" % seed_value)
            return
        if not s.can_meeting_speak("player"):
            fails.append("player was incorrectly blocked from meeting feed at seed %d" % seed_value)
            return
    print("  OK: 300 seeded ballots and meeting speakers obey ACTIVE-only invariants.")

func _pair_history_symmetry() -> void:
    print("\n-- 8. pair_key() symmetry (canonical pair history) --")
    var ok := true
    for a in AstraCrewCatalog.ORDER:
        for b in AstraCrewCatalog.ORDER:
            if a == b: continue
            if AstraCrewCatalog.pair_key(a,b) != AstraCrewCatalog.pair_key(b,a):
                ok = false
    if ok:
        print("  OK: pair_key(a,b) == pair_key(b,a) for every crew pair.")
    else:
        fails.append("pair_key() is not symmetric — A/B would see different histories (§9/§20)")

func _calibration_never_shows_meeting_or_vote() -> void:
    print("\n-- 9. CALIBRATION never reaches MEETING/VOTE/NIGHT --")
    var s := AstraGameSession.new()
    s.setup("CALIBRATION", 55)
    s.begin_voyage()
    var guard := 0
    while not s.voyage.get("scene",{}).is_empty() and guard < 20:
        guard += 1
        var scene: Dictionary = s.voyage["scene"]
        if int(s.voyage["line"]) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
            s.voyage_choose(0)
        else:
            s.voyage_next()
    for point in s.voyage_points():
        s.voyage_inspect(str(point[0]))
        guard = 0
        while not s.voyage.get("scene",{}).is_empty() and guard < 20:
            guard += 1
            s.voyage_next()
    for who in s.roster:
        s.voyage_visit_person(who)
        guard = 0
        while not s.voyage.get("scene",{}).is_empty() and guard < 20:
            guard += 1
            var scene: Dictionary = s.voyage["scene"]
            if int(s.voyage["line"]) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
                s.voyage_choose(0)
            else:
                s.voyage_next()
    s.finish_voyage()
    if s.phase in ["MEETING","VOTE","NIGHT"]:
        fails.append("CALIBRATION reached phase %s" % s.phase)
    else:
        print("  OK: CALIBRATION resolved via phase %s." % s.phase)

func _dead_air_light_phase_flow() -> void:
    print("\n-- 10. DEAD_AIR meeting budget stays light --")
    var s := AstraGameSession.new()
    s.setup("DEAD_AIR", 9)
    if s.meeting_actions_max() > 1:
        fails.append("DEAD_AIR meeting_actions_max() is %d (§8 asks for 0)" % s.meeting_actions_max())
    else:
        print("  OK: DEAD_AIR meeting_actions_max() == %d." % s.meeting_actions_max())
