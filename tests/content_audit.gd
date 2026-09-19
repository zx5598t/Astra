extends SceneTree
# Content-diversity audit (design doc §20). This is a REPORT, not a gate: it
# never fails the build. Its job is to stop "170 scenes exist" from being
# mistaken for "170 scenes are actually different from each other" — the
# checks below are the ones a raw scene count hides.
#   godot --headless --path . --script res://tests/content_audit.gd

func _initialize() -> void:
    print("=== ASTRA CONTENT AUDIT (report only, always exits 0) ===")
    _tag_sets_by_character()
    _scene_counts_by_character()
    _choice_effect_repetition()
    _sentence_openers()
    _pair_scene_distribution()
    _personal_vs_everyday_ratio()
    print("=== end of audit ===")
    quit(0)

func _by_speaker() -> Dictionary:
    var out := {}
    for scene in AstraVoyageContent.SCENES:
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
        print("  FLAG: every character has the identical tag set %s — no character skips or adds a tag." % [str(reference)])
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
        print("  FLAG: scene counts only range %d–%d. Section 10 asks for counts that follow each character's" % [lo, hi])
        print("        personality (e.g. Jun/Maren talkative, Soren quiet-until-the-signal), not a fixed quota.")
    else:
        print("  OK: scene counts range %d–%d." % [lo, hi])
    for who in by_speaker: print("  %s: %d scenes" % [who, by_speaker[who].size()])

func _choice_effect_repetition() -> void:
    print("\n-- 3. Choice effect vocabulary --")
    var effects := {}
    for scene in AstraVoyageContent.SCENES:
        for choice in scene.get("choices", []):
            var effect := str(choice.get("effect", ""))
            effects[effect] = int(effects.get(effect, 0)) + 1
    var keys := effects.keys()
    keys.sort()
    print("  %d distinct effects across all choices: %s" % [keys.size(), str(keys)])
    if keys.size() <= 7:
        print("  FLAG: section 7 asks for the effect vocabulary to grow beyond the original seven")
        print("        (help/record/share/wait/observe/defend/hide) with state-changing choices.")

func _sentence_openers() -> void:
    print("\n-- 4. Repeated opening words in 'action' lines (possible template smell) --")
    var openers := {}
    for scene in AstraVoyageContent.SCENES:
        var action := str(scene.get("action", ""))
        if action == "": continue
        var first_word := action.split(" ")[0] if " " in action else action.substr(0, mini(4, action.length()))
        openers[first_word] = int(openers.get(first_word, 0)) + 1
    var repeated: Array = []
    for word in openers:
        if int(openers[word]) >= 5: repeated.append("%s (%d)" % [word, openers[word]])
    if repeated.is_empty():
        print("  OK: no opening word repeats 5+ times across all scenes.")
    else:
        print("  FLAG: openers repeated 5+ times: %s" % ", ".join(PackedStringArray(repeated)))

func _pair_scene_distribution() -> void:
    print("\n-- 5. NPC-pair ('pair' tag) scene distribution --")
    var pairs := {}
    for scene in AstraVoyageContent.SCENES:
        if str(scene.get("tag","")) != "pair": continue
        var key := str(scene["speaker"]) + ":" + str(scene.get("target",""))
        pairs[key] = int(pairs.get(key,0)) + 1
    print("  %d pair scenes across %d distinct pairings: %s" % [pairs.values().reduce(func(a,b): return a+b, 0), pairs.size(), str(pairs)])
    var full_mesh := AstraCrewCatalog.ORDER.size() * (AstraCrewCatalog.ORDER.size()-1) / 2
    if pairs.size() < 8:
        print("  FLAG: section 12 asks for a real relationship web; %d distinct pairings is thin against %d possible unordered pairs." % [pairs.size(), full_mesh])

func _personal_vs_everyday_ratio() -> void:
    print("\n-- 6. Personal/secret/echo vs. everyday/work ratio, per character --")
    var by_speaker := _by_speaker()
    var personal_tags := ["personal","secret","echo","grief","apology"]
    var everyday_tags := ["everyday","work","observation"]
    var ratios := []
    for who in by_speaker:
        var personal := 0
        var everyday := 0
        for scene in by_speaker[who]:
            var tag := str(scene["tag"])
            if tag in personal_tags: personal += 1
            elif tag in everyday_tags: everyday += 1
        ratios.append("%s %d:%d" % [who, personal, everyday])
    print("  " + ", ".join(PackedStringArray(ratios)))
    print("  (Section 11 asks these ratios to differ by character rather than land on the same split.)")
