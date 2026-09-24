extends SceneTree

# 0.8.0 campaign flow: RELOAD keeps a reconstruction, RETRY makes a new one,
# the explorer's death ends the reconstruction at once (no next Day), the
# explorer carries one line into the retry, and Residual Echo leaves at most
# one unexplained reaction at the next Stage's first morning — never a role.
#   godot --headless --path . --script res://tests/campaign_080_tests.gd

var checks := 0
var failures: Array = []

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        print("FAIL · " + label)

func _initialize() -> void:
    test_reload_keeps_reconstruction()
    test_retry_rerolls()
    test_death_ends_reconstruction()
    test_residual_echo()
    test_echo_lines_never_name_roles()
    test_finale()
    test_player_contact_changes_public_room()
    if failures.is_empty():
        print("ASTRA CAMPAIGN 080 TESTS OK · %d checks" % checks)
        quit()
    else:
        print("ASTRA CAMPAIGN 080 TESTS FAILED · %d/%d" % [failures.size(), checks])
        quit(1)

func _to_conversation(s: AstraGameSession) -> void:
    AstraTestBots._finish_morning(s)
    s.advance()

func test_reload_keeps_reconstruction() -> void:
    var path := "user://astra_campaign080_test.session"
    AstraGameSession.delete_snapshot(path)
    var s := AstraGameSession.new()
    s.setup("RED_SHIFT", 424242, "GUARDIAN")
    s.begin_voyage({})
    _to_conversation(s)
    var first := str(s.living_ids()[0])
    s.ask(first, "STATEMENT")
    check(s.save_snapshot(path), "a reconstruction in progress saves")
    var loaded := AstraGameSession.new()
    check(loaded.load_snapshot(path), "the save loads")
    check(loaded.seed_value == s.seed_value, "RELOAD keeps the seed")
    check(Array(loaded.truth.get("nulls", [])) == Array(s.truth.get("nulls", [])), "RELOAD keeps the Nulls")
    check(str(loaded.current_packet().get("actor", "")) == str(s.current_packet().get("actor", "")), "RELOAD keeps today's actor")
    var ids_a: Array = []
    var ids_b: Array = []
    for item in s.current_packet().get("fragments", []):
        ids_a.append(str(item.get("id", "")) + str(item.get("text", "")))
    for item in loaded.current_packet().get("fragments", []):
        ids_b.append(str(item.get("id", "")) + str(item.get("text", "")))
    check(ids_a == ids_b, "RELOAD keeps the Day Packet word for word")
    check(loaded.phase == s.phase and loaded.day == s.day, "RELOAD keeps the phase and Day")
    check(loaded.conversation_open(first), "RELOAD keeps who was already heard")
    AstraGameSession.delete_snapshot(path)

func test_retry_rerolls() -> void:
    var previous := AstraGameSession.fresh_seed()
    var seeds := {}
    var null_sets := {}
    for i in range(30):
        var next := AstraGameSession.fresh_seed(previous)
        check(next != previous, "RETRY never reuses the seed it replaces")
        seeds[next] = true
        var s := AstraGameSession.new()
        s.setup("GLASS_GARDEN", next)
        var nulls: Array = Array(s.truth.get("nulls", [])).duplicate()
        nulls.sort()
        null_sets[str(nulls)] = true
        check(s.case_id == "GLASS_GARDEN" and s.day == 1, "RETRY is the same Stage from Day 1")
        previous = next
    check(seeds.size() >= 28, "fresh seeds do not repeat")
    check(null_sets.size() >= 4, "retries do not keep the same Null (%d different)" % null_sets.size())

func test_death_ends_reconstruction() -> void:
    var s: AstraGameSession = null
    for seed in range(5150, 5170):
        var candidate := AstraGameSession.new()
        candidate.setup("RED_SHIFT", seed, "NONE")
        candidate.begin_voyage({})
        _to_conversation(candidate)
        candidate.advance()
        candidate._finish_meeting()
        candidate.advance()
        # Vote for an innocent so the Stage goes on into the night.
        var target := ""
        for id in candidate.eligible_vote_targets():
            if str(id) not in candidate.living_null_ids():
                target = str(id)
                break
        candidate.cast_vote(target)
        if candidate.vote_stage() == "RUNOFF":
            candidate.cast_vote(str(candidate.runoff_candidates()[0]))
        if candidate.vote_stage() == "TIEBREAK":
            candidate.resolve_tiebreak(str(candidate.runoff_candidates()[0]))
        if candidate.outcome == "":
            s = candidate
            break
    check(s != null, "found a reconstruction that reaches the night")
    if s == null:
        return
    var day_before := s.day
    s.advance()
    s.stage_state()["player_threat"] = {}
    for id in s.living_null_ids():
        s.stage_state()["player_threat"][id] = 99.0
    if s.phase == "NIGHT" and not s.night_done:
        s.choose_night_action("skip", "")
    elif s.outcome == "":
        s._resolve_night()
    check(not s.player_alive() and s.outcome == "LOSE" and s.outcome_reason() == "player_killed", "the explorer's death ends the reconstruction")
    for _i in range(6):
        s.advance()
    check(s.phase == "RESULT", "a dead explorer goes straight to the result")
    check(s.day == day_before, "no next Day starts after the explorer's death")
    check(not s.save_snapshot("user://astra_campaign080_dead.session"), "a lost reconstruction cannot be saved to be reloaded")
    check(str(s.final_report.get("title", "")) == "재구성 실패", "the result reads as a lost reconstruction")
    var scene := s.story_scene()
    check(str(scene.get("kind", "")) == "failure", "a failure scene plays before the result")
    var post_mortem: Dictionary = Dictionary(s.final_report.get("post_mortem", {}))
    var post_mortem_built := not Array(post_mortem.get("danger", [])).is_empty() or not Array(post_mortem.get("innocent_lies", [])).is_empty() or not Array(post_mortem.get("missed_clues", [])).is_empty()
    check(post_mortem_built, "post-mortem contains concrete failure evidence")
    var memory := s.voyage_memory()
    var echo: Dictionary = memory.get("death_echo", {})
    check(str(echo.get("case_id", "")) == "RED_SHIFT" and str(echo.get("line", "")) != "", "the explorer carries one line into the retry")
    var retry := AstraGameSession.new()
    retry.setup("RED_SHIFT", AstraGameSession.fresh_seed(s.seed_value), "NONE")
    retry.begin_voyage(memory)
    var found := false
    for entry in retry.story_queue():
        if str(entry.get("id", "")).begins_with("death_echo_"):
            found = true
            for line in entry.get("lines", []):
                check("Null" not in str(line[1]), "the carried line never names a role")
    check(found, "the retry's first morning plays the carried line")
    var other := AstraGameSession.new()
    other.setup("SILENT_ORBIT", 777, "GUARDIAN")
    other.begin_voyage(memory)
    for entry in other.story_queue():
        check(not str(entry.get("id", "")).begins_with("death_echo_"), "the carried line belongs to the Stage it was heard in")

func test_residual_echo() -> void:
    var memory := {"echo_events": [{"tag": "fell", "id": "mira"}, {"tag": "defended", "id": "noa"}], "echo_last_stage": 3}
    var s := AstraGameSession.new()
    s.setup("SILENT_ORBIT", 9090, "GUARDIAN")
    s.begin_voyage(memory)
    var echoes := 0
    var protocol_index := -1
    var echo_index := -1
    var queue := s.story_queue()
    for index in range(queue.size()):
        var entry: Dictionary = queue[index]
        if str(entry.get("kind", "")) == "echo":
            echoes += 1
            echo_index = index
        if str(entry.get("kind", "")) == "protocol" and protocol_index < 0:
            protocol_index = index
    check(echoes == 1, "Part II opens with exactly one echo beat (%d)" % echoes)
    check(protocol_index < 0 or echo_index < protocol_index, "the echo comes before the protocol choice")
    var shown := 0
    for stage_case in ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD"]:
        for seed in range(1, 21):
            var t := AstraGameSession.new()
            t.setup(stage_case, seed * 131)
            t.begin_voyage({"echo_events": [{"tag": "shielded", "id": "mira"}], "echo_last_stage": 0})
            for entry in t.story_queue():
                if str(entry.get("kind", "")) == "echo":
                    shown += 1
    check(shown > 10 and shown < 60, "an echo is occasional, not every Stage (%d of 60)" % shown)
    var none := AstraGameSession.new()
    none.setup("DEAD_AIR", 11)
    none.begin_voyage({})
    for entry in none.story_queue():
        check(str(entry.get("kind", "")) != "echo", "no events, no echo")

# The last Stage cleared: one human decision, an epilogue in its tone, the
# campaign's callbacks, ASTRA's last line; never in Deep, never mid-campaign.
func test_finale() -> void:
    for choice_index in range(3):
        var s := AstraGameSession.new()
        s.setup("THRESHOLD", 8080 + choice_index, "GUARDIAN")
        s.begin_voyage({"campaign_tally": {"defended": {"noa": 3}, "sent_wrong": {"rho": 2}, "saved": {"sena": 1}, "deaths": {}}})
        for id in s.living_null_ids():
            s.crew[id].status = AstraCrewMember.STATUS_ISOLATED
        s._check_end("vote")
        s.phase = "RESULT"
        s._queue_result_story()
        check(s.is_campaign_finale(), "clearing THRESHOLD is the campaign finale")
        var guard := 0
        var chose := false
        while not s.story_finished() and guard < 40:
            guard += 1
            var scene := s.story_scene()
            if str(scene.get("id", "")) == "finale_choice":
                s.story_choose(choice_index)
                chose = true
            elif not Array(scene.get("choices", [])).is_empty():
                s.story_choose(0)
            else:
                s.story_next()
        check(chose, "the finale asks one decision")
        var expected: String = ["TRUST", "FRACTURE", "DISCOVERY"][choice_index]
        check(s.finale_tone() == expected, "the decision sets the epilogue tone (%s)" % s.finale_tone())
        var seen: Array = s.stage_state().get("story_seen", [])
        check("epilogue_" + expected.to_lower() in seen, "the epilogue for the tone plays")
        check("finale_callbacks" in seen and "finale_astra" in seen, "callbacks and ASTRA's last line play")
    var deep := AstraGameSession.new()
    deep.setup_deep("THRESHOLD", 9, "NONE", 21, "")
    for id in deep.living_null_ids():
        deep.crew[id].status = AstraCrewMember.STATUS_ISOLATED
    deep._check_end("vote")
    check(not deep.is_campaign_finale(), "Deep never plays the campaign finale")
    var mid := AstraGameSession.new()
    mid.setup("SILENT_ORBIT", 10, "GUARDIAN")
    for id in mid.living_null_ids():
        mid.crew[id].status = AstraCrewMember.STATUS_ISOLATED
    mid._check_end("vote")
    check(not mid.is_campaign_finale(), "only the last Stage ends the campaign")

func test_echo_lines_never_name_roles() -> void:
    for tag in AstraStageStory.ECHO_LINES:
        for npc_id in AstraCrewCatalog.ORDER:
            var pair := AstraStageStory.echo_line(str(tag), str(npc_id))
            check(pair.size() == 2, "echo line exists for %s/%s" % [tag, npc_id])
            for text in pair:
                check("Null" not in str(text) and "{" not in str(text), "echo line is plain residue: %s" % str(text))
    for pool in [AstraStageStory.RESYNC_LOST, AstraStageStory.RESYNC_ISOLATED, AstraStageStory.RESYNC_QUIET]:
        for text in pool:
            check("Null" not in str(text), "re-sync line never names a role")


# Same Stage/seed, same meeting RNG. The only changed input is whether the
# explorer first drew a private fragment out of its owner. That contact must
# materially increase the chance that the fact reaches the public room.
func test_player_contact_changes_public_room() -> void:
    var found := false
    for seed in range(100, 260):
        var passive := AstraGameSession.new()
        passive.setup("GLASS_GARDEN", seed)
        passive.begin_voyage({})
        _to_conversation(passive)
        var packet: Dictionary = passive.current_packet()
        var chosen: Dictionary = {}
        for item in packet.get("fragments", []):
            if str(item.get("type", "")) in ["SYSTEM_RECORD", "DIRECT_WITNESS", "HEARSAY"] and str(item.get("owner", "")) != "":
                chosen = item
                break
        if chosen.is_empty():
            continue
        var active := AstraGameSession.new()
        active.setup("GLASS_GARDEN", seed)
        active.begin_voyage({})
        _to_conversation(active)
        var fact_id := str(chosen.get("id", ""))
        AstraKnowledgeModel.share_with(active.flags, fact_id, "player", active.day, str(chosen.get("owner", "")))
        active._mark_read(fact_id)
        passive.advance()
        active.advance()
        passive._finish_meeting()
        active._finish_meeting()
        var passive_public := AstraKnowledgeModel.is_public(passive.flags, fact_id)
        var active_public := AstraKnowledgeModel.is_public(active.flags, fact_id)
        if active_public and not passive_public:
            var active_log: Array = active.stage_state().get("public_log", [])
            check(active_log.any(func(row): return str(row.get("fact", "")) == fact_id and bool(row.get("player_contact", false))), "public telemetry attributes the exposed fact to prior player contact")
            found = true
            break
    check(found, "same-seed probe finds a Stage 3 room changed by player contact")
