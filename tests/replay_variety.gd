extends SceneTree

# Does the same case actually play differently the second time?
#
#   godot --headless --path . --script res://tests/replay_variety.gd
#   godot --headless --path . --script res://tests/replay_variety.gd -- --seeds=500
#
# The failure this guards against is the one that is invisible in a single
# playthrough and obvious after five: the same person is always Null, the same
# person is always suspected first, the same line opens every meeting. Each
# check has a stated threshold rather than a vague "looks varied", so a
# regression shows up as a number.

var checks := 0
var failures: Array[String] = []
var seeds := 200

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--seeds="):
            seeds = maxi(40, int(argument.split("=")[1]))
    print("REPLAY VARIETY · %d seeds per case" % seeds)
    test_role_distribution()
    test_same_stage_replay()
    test_soft_anti_repeat()
    test_pair_distribution()
    test_innocent_liar_distribution()
    test_opening_line_variety()
    test_ten_run_comparison()
    if failures.is_empty():
        print("ASTRA REPLAY VARIETY OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA REPLAY VARIETY FAILED · %d of %d checks" % [failures.size(), checks])
        quit(1)

# No face may be the villain much more often than any other.
func test_role_distribution() -> void:
    for case_id in AstraCaseCatalog.CAMPAIGN:
        var counts := {}
        for npc_id in AstraCaseCatalog.roster(AstraCaseCatalog.get_case(case_id)):
            counts[npc_id] = 0
        var history: Array = []
        for index in range(seeds):
            var truth := AstraCaseGenerator.generate(case_id, index * 31 + 7, history, "STANDARD")
            for npc_id in truth.get("nulls", []):
                counts[str(npc_id)] = int(counts[str(npc_id)]) + 1
            history.append_array(truth.get("nulls", []))
            while history.size() > 12:
                history.remove_at(0)
        var expected := float(seeds) * AstraCaseCatalog.null_count(AstraCaseCatalog.get_case(case_id)) / float(counts.size())
        var lowest := 1e9
        var highest := -1.0
        for npc_id in counts:
            lowest = minf(lowest, float(counts[npc_id]))
            highest = maxf(highest, float(counts[npc_id]))
        check(lowest > expected * 0.6, "%s: least-used Null still appears often (%d vs %d)" % [case_id, int(lowest), int(expected)])
        check(highest < expected * 1.4, "%s: most-used Null is not dominant (%d vs %d)" % [case_id, int(highest), int(expected)])


# Explicit player-facing same-stage replay gate. Every campaign case is swept
# independently rather than hiding a fixed-role stage inside campaign averages.
func test_same_stage_replay() -> void:
    for case_id in AstraCaseCatalog.CAMPAIGN:
        var data := AstraCaseCatalog.get_case(str(case_id))
        var roster: Array = AstraCaseCatalog.roster(data)
        var wanted := AstraCaseCatalog.null_count(data)
        var identities := {}
        var pairs := {}
        var previous := ""
        var consecutive := 0
        for index in range(seeds):
            var truth := AstraCaseGenerator.generate(str(case_id),510000 + index * 101, [], "STANDARD")
            var nulls: Array = truth.get("nulls",[]).duplicate()
            for npc_id in nulls:
                identities[str(npc_id)] = int(identities.get(str(npc_id),0)) + 1
            nulls.sort()
            var key := ":".join(PackedStringArray(nulls))
            pairs[key] = true
            if key == previous:
                consecutive += 1
            previous = key
        check(identities.size() >= mini(roster.size(), maxi(2, roster.size()-1)),
            "%s: same-stage replay uses multiple Null identities (%d/%d)" % [case_id,identities.size(),roster.size()])
        if wanted >= 2:
            var possible_pairs := roster.size() * (roster.size()-1) / 2
            var required_pairs := mini(possible_pairs, maxi(3, int(ceil(float(possible_pairs) * 0.55))))
            check(pairs.size() >= required_pairs,
                "%s: two-Null replay covers varied pairs (%d/%d possible)" % [case_id,pairs.size(),possible_pairs])
        else:
            check(identities.size() >= mini(roster.size(),3),
                "%s: one-Null replay does not collapse to one face" % case_id)
        print("  SAME-STAGE %s · seeds %d · identities %s · pairs %d · consecutive %d" % [case_id,seeds,JSON.stringify(identities),pairs.size(),consecutive])

# Recent history must lower repeat pressure without becoming a hard cooldown.
func test_soft_anti_repeat() -> void:
    for case_id in AstraCaseCatalog.CAMPAIGN:
        var data := AstraCaseCatalog.get_case(str(case_id))
        var roster: Array = AstraCaseCatalog.roster(data)
        if roster.size() < 2:
            continue
        var recent := str(roster[0])
        var baseline_hits := 0
        var penalized_hits := 0
        var history := [recent]
        for index in range(seeds * 2):
            var seed_value := 710000 + index * 131
            var baseline := AstraCaseGenerator.generate(str(case_id),seed_value,[],"STANDARD")
            var penalized := AstraCaseGenerator.generate(str(case_id),seed_value,history,"STANDARD")
            if recent in baseline.get("nulls",[]): baseline_hits += 1
            if recent in penalized.get("nulls",[]): penalized_hits += 1
        check(penalized_hits < baseline_hits,
            "%s: recent-history penalty lowers repeat frequency (%d < %d)" % [case_id,penalized_hits,baseline_hits])
        check(penalized_hits > 0,
            "%s: recent Null remains selectable; no hard exclusion" % case_id)
        var a := AstraCaseGenerator.generate(str(case_id),818181,history,"STANDARD")
        var b := AstraCaseGenerator.generate(str(case_id),818181,history,"STANDARD")
        check(str(a.get("nulls",[])) == str(b.get("nulls",[])),
            "%s: same seed + same history keeps Null assignment deterministic" % case_id)
        check(str(a.get("positions",{})) == str(b.get("positions",{})),
            "%s: same seed + same history keeps layout deterministic" % case_id)
        check(str(a.get("herring","")) == str(b.get("herring","")),
            "%s: same seed + same history keeps herring deterministic" % case_id)
        print("  SOFT-REPEAT %s · recent %s · baseline %d · penalized %d" % [case_id,recent,baseline_hits,penalized_hits])

# The two-Null pairing must not collapse onto a handful of duos.
func test_pair_distribution() -> void:
    var pairs := {}
    var history: Array = []
    for index in range(seeds * 2):
        var truth := AstraCaseGenerator.generate("LAST_LIGHT", index * 17 + 3, history, "STANDARD")
        var nulls: Array = truth.get("nulls", []).duplicate()
        nulls.sort()
        var key := ":".join(PackedStringArray(nulls))
        pairs[key] = int(pairs.get(key, 0)) + 1
        history.append_array(truth.get("nulls", []))
        while history.size() > 12:
            history.remove_at(0)
    # Eight people give 28 unordered pairs; a healthy spread hits most of them.
    check(pairs.size() >= 24, "Null pairs stay varied (%d distinct pairs)" % pairs.size())
    var worst := 0
    for key in pairs:
        worst = maxi(worst, int(pairs[key]))
    var expected := float(seeds * 2) / 28.0
    check(float(worst) < expected * 2.2, "no single Null pair dominates (%d vs %d)" % [worst, int(expected)])

# The innocent who lies for private reasons should also move around.
func test_innocent_liar_distribution() -> void:
    var counts := {}
    for npc_id in AstraCrewCatalog.ORDER:
        counts[npc_id] = 0
    for index in range(seeds):
        var truth := AstraCaseGenerator.generate("LAST_LIGHT", index * 13 + 11, [], "STANDARD")
        var herring := str(truth.get("herring", ""))
        counts[herring] = int(counts.get(herring, 0)) + 1
    var expected := float(seeds) / float(AstraCrewCatalog.ORDER.size())
    for npc_id in counts:
        check(float(counts[npc_id]) > expected * 0.4, "%s takes a turn as the innocent liar (%d)" % [npc_id, int(counts[npc_id])])

# The same character must not open every meeting with the same sentence.
func test_opening_line_variety() -> void:
    var first_lines := {}
    var all_lines := {}
    var total_lines := 0
    for index in range(30):
        var s := _play_to_meeting("LAST_LIGHT", index * 97 + 5)
        if s.meeting_feed.is_empty():
            continue
        first_lines[str(s.meeting_feed[0].get("text", ""))] = true
        for entry in s.meeting_feed:
            var key := "%s|%s" % [str(entry.get("speaker", "")), str(entry.get("text", ""))]
            all_lines[key] = int(all_lines.get(key, 0)) + 1
            total_lines += 1
    check(first_lines.size() >= 10, "meetings do not all open the same way (%d distinct openings in 30)" % first_lines.size())
    var worst := 0
    for key in all_lines:
        worst = maxi(worst, int(all_lines[key]))
    # A given character-line pair repeating in more than half the runs means the
    # variant pool for that intent is too thin.
    check(worst <= 22, "no single line dominates the meetings (worst repeats %d over %d lines)" % [worst, total_lines])

# Ten runs of one case, compared the way a player comparing sessions would.
func test_ten_run_comparison() -> void:
    var runs: Array = []
    var history: Array = []
    for index in range(10):
        var s := AstraGameSession.new()
        s.setup("LAST_LIGHT", 4200 + index * 811, "ANALYST", "STANDARD", history)
        history.append_array(s.truth.get("nulls", []))
        var nulls: Array = s.truth.get("nulls", []).duplicate()
        nulls.sort()
        runs.append({
            "nulls": ":".join(PackedStringArray(nulls)),
            "herring": str(s.truth.get("herring", "")),
            "mutual": bool(s.truth.get("mutual_alibi", false)),
            "first_clue": str(s.clues[0].get("id", "")) if not s.clues.is_empty() else "",
            "positions": str(s.truth.get("positions", {}))
        })
    var distinct_nulls := {}
    var distinct_herrings := {}
    var distinct_positions := {}
    for run in runs:
        distinct_nulls[str(run["nulls"])] = true
        distinct_herrings[str(run["herring"])] = true
        distinct_positions[str(run["positions"])] = true
    # With 28 possible pairs, ten draws are expected to produce about 8.5
    # distinct ones. A single window of ten can legitimately land at 7, so the
    # floor is per-window and the average is checked across several windows.
    check(distinct_nulls.size() >= 7, "ten runs give at least seven different Null pairs (%d)" % distinct_nulls.size())
    check(distinct_herrings.size() >= 5, "ten runs give at least five different innocent liars (%d)" % distinct_herrings.size())
    check(distinct_positions.size() == 10, "ten runs never repeat the same arrangement of people")
    print("  10-run sample · null pairs %d · innocent liars %d · layouts %d" % [distinct_nulls.size(), distinct_herrings.size(), distinct_positions.size()])

    var window_total := 0
    var windows := 12
    for window in range(windows):
        var pairs := {}
        var window_history: Array = []
        for index in range(10):
            var s := AstraGameSession.new()
            s.setup("LAST_LIGHT", 90000 + window * 1000 + index * 137, "ANALYST", "STANDARD", window_history)
            var nulls_in_run: Array = s.truth.get("nulls", []).duplicate()
            window_history.append_array(nulls_in_run)
            nulls_in_run.sort()
            pairs[":".join(PackedStringArray(nulls_in_run))] = true
        check(pairs.size() >= 6, "window %d keeps ten runs varied (%d pairs)" % [window, pairs.size()])
        window_total += pairs.size()
    var average := float(window_total) / float(windows)
    check(average >= 7.8, "ten-run windows average at least 7.8 distinct Null pairs (%.1f)" % average)
    print("  average distinct Null pairs over %d windows of ten: %.1f" % [windows, average])

    # Determinism: the same seed and the same history replays identically, so QA
    # can still reproduce a report (§74).
    var a := AstraGameSession.new()
    a.setup("LAST_LIGHT", 31337, "ANALYST", "STANDARD")
    var b := AstraGameSession.new()
    b.setup("LAST_LIGHT", 31337, "ANALYST", "STANDARD")
    check(str(a.truth.get("nulls", [])) == str(b.truth.get("nulls", [])), "the same seed replays the same case")
    check(str(a.truth.get("positions", {})) == str(b.truth.get("positions", {})), "the same seed replays the same layout")

func _play_to_meeting(case_id: String, seed_value: int) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value, "ANALYST", "STANDARD")
    s.advance()
    for room_id in s.room_ids():
        while s.investigation_ap > 0:
            if s.search_room(room_id).is_empty():
                break
    s.advance()
    for npc_id in s.living_ids():
        if not s.pending_event.is_empty():
            s.resolve_private_event(0)
        if s.talk_ap > 0:
            s.ask(npc_id, "ALIBI")
    if not s.pending_event.is_empty():
        s.resolve_private_event(0)
    s.advance()
    return s
