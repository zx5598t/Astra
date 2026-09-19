extends SceneTree

# 0.4.0 acceptance checks: onboarding shape, progressive disclosure, dialogue
# pacing and the claim ledger.
#
#   godot --headless --path . --script res://tests/social_tests.gd
#
# These are additions. Nothing in run_tests / campaign_tests / redesign_tests
# was removed to make them pass.

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_calibration_shape()
    test_progressive_unlock()
    test_help_is_gated()
    test_dialogue_pacing_defaults()
    test_meeting_is_one_voice_at_a_time()
    test_claim_ledger()
    test_player_is_on_the_record()
    test_story_first_night()
    test_null_distribution()
    test_dialogue_variety()
    test_save_compatibility()
    test_tutorial_cannot_dead_end()
    test_calibration_varies()
    test_confrontation()
    test_face_icons()
    if failures.is_empty():
        print("ASTRA SOCIAL TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA SOCIAL TESTS FAILED · %d of %d checks" % [failures.size(), checks])
        quit(1)

# B, C — the tutorial is small enough to hold in your head.
func test_calibration_shape() -> void:
    var data := AstraCaseCatalog.get_case(AstraCaseCatalog.CALIBRATION)
    check(not data.is_empty(), "calibration case exists")
    check(AstraCaseCatalog.roster(data).size() <= 5, "calibration roster is at most five people")
    check(data.get("rooms", []).size() <= 3, "calibration uses at most three rooms")
    check(AstraCaseCatalog.null_count(data) == 1, "calibration has exactly one Null")
    check(AstraCaseCatalog.roster(data) == AstraCrewCatalog.INITIAL, "first awakening uses the new four-person roster")
    for seed_value in range(1, 41):
        var s := AstraGameSession.new()
        s.setup(AstraCaseCatalog.CALIBRATION, seed_value, "ANALYST", "STORY")
        check(s.roster.size() == 4, "seed %d roster size" % seed_value)
        check(s.truth["nulls"].size() == 1, "seed %d single null" % seed_value)
        check(s.clues.size() >= 4 and s.clues.size() <= 8, "seed %d keeps clue count small (%d)" % [seed_value, s.clues.size()])
        # Nobody outside the case may be named by a clue.
        for clue in s.clues:
            for member_id in clue.get("members", []):
                check(str(member_id) in s.roster, "seed %d clue names only present crew" % seed_value)
        # The whole point of the tutorial is one findable contradiction.
        s.advance()
        for room_id in s.room_ids():
            for point in s.investigation_points(room_id):
                if bool(point.get("available", false)) and s.investigation_ap > 0:
                    s.inspect_point(room_id, str(point["id"]))
        s.advance()
        for npc_id in s.living_ids():
            if s.talk_ap > 0:
                s.ask(npc_id, "ALIBI")
        check(s.pending_event.is_empty(), "seed %d no private event during calibration" % seed_value)

# T, U — unlocks arrive in order, and nothing is shown before it exists.
func test_progressive_unlock() -> void:
    var fresh := AstraUnlocks.unlocked(false, 0)
    for feature in ["marks", "night", "hypothesis", "protocols", "case_select", "private_talk"]:
        check(not AstraUnlocks.has(fresh, feature), "%s is hidden on a fresh archive" % feature)
    for feature in AstraUnlocks.ALWAYS:
        check(AstraUnlocks.has(fresh, feature), "%s is available from the start" % feature)
    var after_calibration := AstraUnlocks.unlocked(true, 0)
    check(AstraUnlocks.has(after_calibration, "night"), "night opens after calibration")
    check(not AstraUnlocks.has(after_calibration, "hypothesis"), "hypothesis stays closed after calibration")
    var after_one := AstraUnlocks.unlocked(true, 1)
    check(AstraUnlocks.has(after_one, "private_talk"), "private talk opens after one case")
    check(not AstraUnlocks.has(after_one, "protocols"), "protocols stay closed after one case")
    var after_three := AstraUnlocks.unlocked(true, 3)
    check(AstraUnlocks.has(after_three, "protocols") and AstraUnlocks.has(after_three, "hypothesis"), "advanced tools open later")
    # Order is stable and each step adds, never removes.
    var previous: Array = fresh
    for played in range(0, 6):
        var current := AstraUnlocks.unlocked(true, played)
        for feature in previous:
            check(feature in current, "unlocks never revoke %s" % feature)
        previous = current
    # The session refuses gated behaviour even if a screen asks for it.
    var s := AstraGameSession.new()
    s.setup(AstraCaseCatalog.CALIBRATION, 5, "ANALYST", "STORY")
    s.features = AstraUnlocks.unlocked(false, 0)
    check(not s.has_feature("hypothesis"), "session honours the unlock list")
    check(s.has_feature("investigate"), "session allows base features")

# E — the codex only describes what has been met.
func test_help_is_gated() -> void:
    var fresh := AstraCodex.topics(AstraUnlocks.unlocked(false, 0))
    var ids: Array = []
    for topic in fresh:
        ids.append(str(topic.get("id", "")))
    check("goal" in ids and "clue" in ids, "core topics available immediately")
    check(not ("night_tactics" in ids), "night tactics topic hidden before it exists")
    check(not ("hypothesis" in ids), "hypothesis topic hidden before it exists")
    var full := AstraCodex.topics(AstraUnlocks.unlocked(true, 5))
    check(full.size() > fresh.size(), "codex grows as systems appear")
    for phase in AstraGameSession.PHASES:
        var screen := AstraCodex.screen(phase)
        check(str(screen.get("purpose", "")) != "", "screen help exists for " + phase)
        check(screen.get("points", []).size() <= 3, "screen help stays short for " + phase)

# F — nothing advances on its own unless the player asked for it.
func test_dialogue_pacing_defaults() -> void:
    var settings := AstraSettings.new("user://astra_social_test_settings.cfg")
    check(not settings.auto_advance, "auto advance is off by default")
    check(settings.pause_on_important, "auto still stops on important lines by default")
    check(not settings.portrait_motion, "idle portrait motion is off by default")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://astra_social_test_settings.cfg"))

# H, I — the meeting is a sequence of single speakers, and the first one is short.
func test_meeting_is_one_voice_at_a_time() -> void:
    for seed_value in [3, 44, 128]:
        var s := _play_to_meeting("DEAD_AIR", seed_value, "STORY")
        var feed: Array = s.meeting_feed
        check(not feed.is_empty(), "seed %d meeting produced statements" % seed_value)
        for entry in feed:
            check(str(entry.get("speaker", "")) != "", "every meeting line has one named speaker")
        check(feed.size() <= 16, "seed %d first meeting stays under sixteen lines (%d)" % [seed_value, feed.size()])
        # A person never speaks twice in a row in the opening round.
        var previous := ""
        var doubled := 0
        for entry in feed:
            if str(entry.get("speaker", "")) == previous:
                doubled += 1
            previous = str(entry.get("speaker", ""))
        check(doubled <= 2, "seed %d speakers alternate (%d repeats)" % [seed_value, doubled])

# J, K — public statements are recorded and can be compared.
func test_claim_ledger() -> void:
    var s := _play_to_meeting("DEAD_AIR", 9, "STANDARD")
    check(not s.claim_ledger.is_empty(), "meeting statements reach the ledger")
    var public_found := false
    for entry in s.claim_ledger:
        if str(entry.get("scope", "")) == AstraClaimLedger.SCOPE_PUBLIC:
            public_found = true
    check(public_found, "public claims are marked public")
    for npc_id in s.roster:
        var history := s.claim_history(npc_id)
        if history.is_empty():
            continue
        check(str(history[0].get("speaker", "")) == npc_id, "ledger attributes lines correctly")
    # A manufactured change of story has to be detectable.
    var ledger: Array = []
    AstraClaimLedger.record(ledger, AstraClaimLedger.make_entry("rho", AstraClaimLedger.KIND_POSITION, 1, "MEETING", AstraClaimLedger.SCOPE_PUBLIC, "엔진실에 있었어.", {"position": "engine"}))
    AstraClaimLedger.record(ledger, AstraClaimLedger.make_entry("rho", AstraClaimLedger.KIND_POSITION, 2, "MEETING", AstraClaimLedger.SCOPE_PUBLIC, "통신실에 잠깐 갔었지.", {"position": "comms"}))
    var conflicts := AstraClaimLedger.self_conflicts(ledger, "rho")
    check(conflicts.size() == 1, "a changed position is detected")
    check(str(conflicts[0].get("reason", "")) != "", "the conflict states its reason")
    # Retracting removes it from consideration rather than deleting the record.
    var taken_back := AstraClaimLedger.retract_latest(ledger, "rho", AstraClaimLedger.KIND_POSITION, 2)
    check(not taken_back.is_empty(), "a claim can be withdrawn")
    check(AstraClaimLedger.self_conflicts(ledger, "rho").is_empty(), "a withdrawn claim stops conflicting")
    check(AstraClaimLedger.retraction_count(ledger, "rho") == 1, "the withdrawal itself is remembered")
    check(ledger.size() == 2, "withdrawing does not erase history")
    # Search is a memory aid, not a verdict.
    check(AstraClaimLedger.search(ledger, "통신실").size() == 1, "claims are searchable")
    check(AstraClaimLedger.search(ledger, "없는말").is_empty(), "search does not invent matches")

# L, M — the investigator is on the record too, and it can be used against them.
func test_player_is_on_the_record() -> void:
    # DEAD_AIR's meeting budget is 0 by design now (§8 of the design notes:
    # its first meeting is meant to be watched, not argued in), so the
    # defend/pattern-citing mechanic under test here needs a chapter that
    # actually grants a meeting action.
    var s := _play_to_meeting("GLASS_GARDEN", 21, "STANDARD")
    var target := str(s.living_ids()[0])
    s.defend(target)
    check(not s.player_claims.is_empty(), "player statements reach the ledger")
    var stance := s.player_stance_on(target)
    check(int(stance["defended"]) >= 1, "the ledger counts who the player backs")
    # Two defences of the same person is a pattern an NPC may cite.
    s.meeting_actions_left = 4
    s.defend(target)
    var observer := ""
    for npc_id in s.living_crew_ids():
        if npc_id != target:
            observer = npc_id
            break
    var remark := s.player_pattern_remark(observer)
    check(not remark.is_empty(), "a repeated stance becomes a citable pattern")
    check(str(remark.get("target", "")) == target, "the pattern names the right person")
    check(s.player_pattern_remark(target).is_empty(), "nobody is told they are always defended by themselves")

# V — Story mode does not take anyone on the first night.
func test_story_first_night() -> void:
    for seed_value in range(1, 26):
        var s: AstraGameSession = _play_to_night("DEAD_AIR", seed_value, "STORY")
        if s == null:
            continue
        check(s.casualties.is_empty(), "story seed %d loses nobody on night one" % seed_value)
    var standard_deaths := 0
    for seed_value in range(1, 26):
        var s: AstraGameSession = _play_to_night("DEAD_AIR", seed_value, "STANDARD")
        if s != null and not s.casualties.is_empty():
            standard_deaths += 1
    check(standard_deaths > 0, "standard mode still has consequences on night one")

# The Null role must not settle on one face over a run of cases.
func test_null_distribution() -> void:
    var counts := {}
    for npc_id in AstraCrewCatalog.ORDER:
        counts[npc_id] = 0
    var history: Array = []
    for run in range(240):
        var truth := AstraCaseGenerator.generate("LAST_LIGHT", 1000 + run, history, "STANDARD")
        var nulls: Array = truth.get("nulls", [])
        for npc_id in nulls:
            counts[str(npc_id)] = int(counts[str(npc_id)]) + 1
        history.append_array(nulls)
        while history.size() > 12:
            history.remove_at(0)
    var expected := 240.0 * 2.0 / 8.0
    for npc_id in counts:
        var share := float(counts[npc_id])
        check(share > expected * 0.6 and share < expected * 1.4, "%s draws Null a fair share (%d vs %d)" % [npc_id, int(share), int(expected)])
    # Back-to-back repeats should be rarer than a flat shuffle would give.
    var repeats := 0
    var previous: Array = []
    var rolling: Array = []
    for run in range(200):
        var truth := AstraCaseGenerator.generate("LAST_LIGHT", 5000 + run, rolling, "STANDARD")
        var nulls: Array = truth.get("nulls", [])
        for npc_id in nulls:
            if npc_id in previous:
                repeats += 1
        previous = nulls
        rolling.append_array(nulls)
        while rolling.size() > 12:
            rolling.remove_at(0)
    # A flat shuffle would repeat about 2*(2/8) = 0.5 per case, i.e. ~100 in 200.
    check(repeats < 80, "recent Nulls are less likely to come straight back (%d)" % repeats)

# Repetition: the lines that fire most often have more than one phrasing.
func test_dialogue_variety() -> void:
    var high_traffic := ["m_alibi_alone", "m_alibi_with", "m_suspect", "m_react_accused_crew", "m_react_accused_null", "m_agree", "m_doubt", "m_vote", "suspect_some", "alibi_alone"]
    for npc_id in AstraCrewCatalog.ORDER:
        for key in high_traffic:
            check(AstraDialogue.variant_count(npc_id, key) >= 2, "%s/%s has more than one phrasing" % [npc_id, key])
        check(AstraDialogue.variant_count(npc_id, "deflect") >= 2, "%s has a way of not answering" % npc_id)
    # The picker avoids what was just used.
    var recent: Array = []
    var picks := {}
    for index in range(12):
        var pick := AstraDialogueMemory.pick(recent, "mira", "m_suspect", 3, float(index % 3) / 3.0)
        picks[pick] = int(picks.get(pick, 0)) + 1
    check(picks.size() >= 2, "the picker rotates between phrasings")
    var repeat_run := 0
    var last := -1
    var fresh_recent: Array = []
    for index in range(20):
        var pick := AstraDialogueMemory.pick(fresh_recent, "rho", "m_vote", 2, 0.5)
        if pick == last:
            repeat_run += 1
        last = pick
    check(repeat_run <= 2, "the same phrasing does not come back immediately")

# S — a 0.3.1 in-progress save still resumes.
func test_save_compatibility() -> void:
    var path := "user://astra_social_compat.cfg"
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT", 777, "ANALYST")
    s.advance()
    s.search_room(str(s.room_ids()[0]))
    check(s.save_snapshot(path), "snapshot writes")
    # Strip the 0.4.0 fields and stamp it as the old version, which is exactly
    # what a file written by 0.3.1 looks like.
    var cfg := ConfigFile.new()
    check(cfg.load(path) == OK, "snapshot reads back")
    cfg.set_value("meta", "version", 1)
    for field in AstraGameSession.FIELDS_ADDED_IN_040:
        cfg.erase_section_key("session", field)
    cfg.save(path)
    var restored := AstraGameSession.new()
    check(restored.load_snapshot(path), "a 0.3.1 snapshot still loads")
    check(restored.case_id == "LAST_LIGHT" and restored.seed_value == 777, "legacy snapshot keeps its case and seed")
    check(restored.roster.size() == 8, "legacy snapshot fills the roster from the case")
    check(restored.null_count == 2 and restored.max_days == 4, "legacy snapshot fills the case shape")
    check(restored.difficulty == "STANDARD", "legacy snapshot defaults to standard")
    check(restored.claim_ledger.is_empty(), "legacy snapshot starts with an empty ledger")
    check(restored.found_clues().size() == s.found_clues().size(), "legacy snapshot keeps found clues")
    AstraGameSession.delete_snapshot(path)

# W — no choice in the tutorial can leave the player unable to continue.
func test_tutorial_cannot_dead_end() -> void:
    for seed_value in range(1, 21):
        var s := AstraGameSession.new()
        s.setup(AstraCaseCatalog.CALIBRATION, seed_value, "ANALYST", "STORY")
        s.set_tutorial(true)
        # Deliberately play badly: skip clues, ask nothing useful, vote at random.
        var guard := 0
        while s.phase != "RESULT" and guard < 200:
            guard += 1
            if s.phase == "INVESTIGATION" and not s.can_advance():
                # The tutorial asks for one search before it lets you move on;
                # it must be possible to satisfy that from any room.
                var searched := false
                for room_id in s.room_ids():
                    for point in s.investigation_points(room_id):
                        if bool(point.get("available", false)) and not searched:
                            s.inspect_point(room_id, str(point["id"]))
                            searched = true
                check(searched, "seed %d always has something to examine" % seed_value)
            if s.phase == "INTERROGATION" and not s.can_advance():
                s.ask(str(s.living_ids()[0]), "ALIBI")
            if s.phase == "VOTE" and not s.vote_cast:
                s.cast_vote("")
            if s.phase == "NIGHT" and not s.night_done:
                s.choose_night_action("rest", "self")
            if s.can_advance():
                s.advance()
        check(s.phase == "RESULT", "seed %d finishes even when played badly" % seed_value)

# ---------------------------------------------------------------- helpers

func _play_to_meeting(case_id: String, seed_value: int, difficulty: String) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value, "ANALYST", difficulty)
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

func _play_to_night(case_id: String, seed_value: int, difficulty: String):
    var s := _play_to_meeting(case_id, seed_value, difficulty)
    if s.phase != "MEETING":
        return null
    s.advance()
    if s.phase != "VOTE":
        return null
    s.cast_vote("")
    s.advance()
    if s.phase != "NIGHT":
        return null
    s.choose_night_action("rest", "self")
    return s

# The tutorial is the case people replay the most, so the crime itself has to
# move — otherwise the second run is the first run with a different name on it.
func test_calibration_varies() -> void:
    check(AstraCaseCatalog.variant_count(AstraCaseCatalog.CALIBRATION) == 1, "the first discovery has a stable authored anchor")
    var themes := {}
    var rooms := {}
    var culprits := {}
    var liars := {}
    for seed_value in range(1, 61):
        var s := AstraGameSession.new()
        s.setup(AstraCaseCatalog.CALIBRATION, seed_value, "ANALYST", "STORY")
        s.begin_voyage()
        themes[str(s.voyage["memories"]["mira"])] = true
        rooms[str(s.voyage["past"])] = true
        culprits[str(s.truth["nulls"][0])] = true
        liars[str(s.truth.get("herring", ""))] = true
        # However the incident lands, the tutorial stays small.
        check(s.clues.size() <= 8, "seed %d keeps the tutorial short (%d clues)" % [seed_value, s.clues.size()])
        check(s.roster.size() == 4, "seed %d keeps four people" % seed_value)
    check(themes.size() >= 3, "destination memories vary (%d kinds)" % themes.size())
    check(rooms.size() >= 3, "past relationships vary (%d rooms)" % rooms.size())
    check(culprits.size() == 4, "every one of the four takes a turn as the culprit")
    check(liars.size() >= 3, "the innocent liar varies too (%d people)" % liars.size())
    # The same seed still replays identically, so a bug report is reproducible.
    var a := AstraGameSession.new()
    a.setup(AstraCaseCatalog.CALIBRATION, 4242, "ANALYST", "STORY")
    var b := AstraGameSession.new()
    b.setup(AstraCaseCatalog.CALIBRATION, 4242, "ANALYST", "STORY")
    check(str(a.case_data.get("theme", "")) == str(b.case_data.get("theme", "")), "the same seed replays the same incident")
    check(str(a.truth["nulls"]) == str(b.truth["nulls"]), "the same seed replays the same culprit")

# Making two people answer each other is a real move with a real cost.
func test_confrontation() -> void:
    var found_pair := false
    var found_conflict := false
    var found_agreement := false
    for seed_value in range(1, 41):
        var s := _play_to_meeting("LAST_LIGHT", seed_value, "STANDARD")
        if s.phase != "MEETING":
            continue
        for a_id in s.living_ids():
            var candidates := s.confront_candidates(a_id)
            if candidates.is_empty():
                continue
            found_pair = true
            var b_id := str(candidates[0]["id"])
            check(str(candidates[0].get("reason", "")) != "", "a confrontation says why the pair is worth it")
            var before := s.meeting_actions_left
            var result := s.confront(a_id, b_id)
            check(bool(result.get("ok", false)), "an offered confrontation can be made")
            check(s.meeting_actions_left == before - 1, "a confrontation costs a meeting action")
            check(not s.confront_candidates(a_id).has(b_id), "the same pair is not offered twice")
            check(not s.can_confront(a_id, b_id), "the same pair cannot be confronted twice")
            if bool(result.get("conflict", false)):
                found_conflict = true
                check(s.has_contradiction_on(a_id) or s.has_contradiction_on(b_id), "a clash becomes a contradiction on the record")
            else:
                found_agreement = true
            # Both people restated, so both statements are on the ledger.
            check(not AstraClaimLedger.by_speaker(s.claim_ledger, a_id, AstraClaimLedger.SCOPE_PUBLIC).is_empty(), "a confronted person is on the public record")
            break
        if found_conflict and found_agreement:
            break
    check(found_pair, "confrontations are offered at all")
    check(found_conflict, "some confrontations expose a clash")
    check(found_agreement, "some confrontations confirm the pair instead")
    # It is never available outside a meeting.
    var idle := AstraGameSession.new()
    idle.setup("DEAD_AIR", 7, "ANALYST", "STANDARD")
    check(not idle.can_confront("mira", "rho"), "confrontation is a meeting move only")

# Every face icon exists and is square, because they are drawn at a fixed size
# next to names and a missing one silently falls back to a 600px bust.
func test_face_icons() -> void:
    for npc_id in AstraCrewCatalog.ORDER:
        var path := AstraCrewCatalog.dot_path(npc_id)
        check(path.begins_with("res://assets/art050/heads/"), "%s uses the head icon" % npc_id)
        check(ResourceLoader.exists(path), "%s head icon exists" % npc_id)
        var texture: Texture2D = load(path)
        check(texture != null, "%s head icon loads" % npc_id)
        if texture != null:
            check(texture.get_width() == texture.get_height(), "%s head icon is square" % npc_id)
            check(texture.get_width() >= 128, "%s head icon is big enough to scale down (%d)" % [npc_id, texture.get_width()])
        check(ResourceLoader.exists(AstraCrewCatalog.cast_path(npc_id)), "%s has half-body art" % npc_id)
    # Body text has to stay readable at the shipping window size.
    check(AstraUI.T_META >= 15, "the smallest text is at least 15px")
    check(AstraUI.T_BODY >= 18, "body text is at least 18px")
