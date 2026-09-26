extends SceneTree

var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    _catalog_and_truth()
    _meeting()
    await _mechanics()
    _distance_motion()
    _art_and_voice()
    if failures.is_empty():
        print("ASTRA HUMAN VARIABLE 090 TESTS OK · %d checks" % checks)
    quit(0 if failures.is_empty() else 1)

func _catalog_and_truth() -> void:
    var names := {}
    for id in AstraExplorerCatalog.ORDER:
        var profile := AstraExplorerCatalog.profile_for(id)
        check(not names.has(profile["name"]), "unique explorer name")
        names[profile["name"]] = true
        check(profile["art_id"] != id, "identity independent of art")
        check(ResourceLoader.exists(AstraExplorerCatalog.face_path(profile)), "usable explicit art fallback")
        check(ResourceLoader.exists(AstraPixelActor.player_sheet(str(profile["art_id"]))), "mapped pixel sheet exists")
        var meta := AstraMetaProgress.new("user://human090_profile.cfg")
        meta.set_player_profile_for_slot(1, profile)
        meta.save_data()
        var restored := AstraMetaProgress.new("user://human090_profile.cfg")
        restored.load_data()
        check(restored.player_profile_for_slot(1) == profile, "slot identity round trip")
    check(names.size() == 6, "six identities")
    check(absf(AstraExplorerCatalog.TONE_NUDGE) <= 0.02, "explorer first-contact trust nudge stays bounded")
    var legacy := AstraExplorerCatalog.normalize({"name": "기존이름", "preset": "p3"})
    check(legacy["explorer_id"] == "neutral" and legacy["preset"] == "p3" and legacy["name"] == "기존이름", "legacy is neutral with same art/name")
    check(AstraExplorerCatalog.normalize({"explorer_id": "bad", "preset": "../../x"})["preset"] == "p1", "invalid profile safe")
    for case_id in ["CALIBRATION", "DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD", "SILENT_ORBIT"]:
        for seed in [4242, 5151, 7919]:
            var baseline := AstraGameSession.new()
            baseline.setup(case_id, seed)
            var wordings := {}
            for id in AstraExplorerCatalog.ORDER:
                var s := AstraGameSession.new()
                s.setup(case_id, seed)
                s.set_player_profile(AstraExplorerCatalog.profile_for(id))
                check(s.current_packet() == baseline.current_packet(), "same truth %s/%s/%d" % [case_id,id,seed])
                check(s.living_null_ids() == baseline.living_null_ids(), "same Null assignment")
                AstraTestBots._finish_morning(s)
                s.advance()
                var npc_id := str(s.living_ids()[0])
                var result := s.ask(npc_id, "STATEMENT")
                var words := ""
                for line in result.get("lines", []):
                    if str(line.get("speaker", "")) == "player":
                        words += str(line["text"])
                wordings[words] = true
                check(not words.is_empty() and "{time}" not in words, "actual formatted player dialogue")
                check(s.current_packet() == baseline.current_packet(), "talk does not rewrite truth")
                check(s.save_snapshot("user://human090.session"), "save new identity")
                var loaded := AstraGameSession.new()
                check(loaded.load_snapshot("user://human090.session"), "load new identity")
                check(loaded.player_profile() == s.player_profile() and loaded.current_packet() == s.current_packet(), "snapshot retains profile/truth")
                check(loaded.question_options(npc_id) == s.question_options(npc_id), "snapshot preserves wording/choices")
            check(wordings.size() == 6, "six actual conversation voices")

func _meeting() -> void:
    var windows := 0
    var responses := 0
    for seed in range(1, 15):
        var s := AstraGameSession.new()
        s.setup("GLASS_GARDEN", seed*7919+17)
        AstraTestBots._finish_morning(s)
        s.advance()
        for npc_id in s.living_ids():
            if s.conversations_left() > 0:
                s.ask(str(npc_id), "STATEMENT")
        s.advance()
        var packet := s.current_packet().duplicate(true)
        var guard := 0
        while not s.meeting_over() and guard < 10:
            guard += 1
            var options := s.clarification_options()
            if not options.is_empty():
                windows += 1
                var before := s.meeting_actions_left
                var result := s.intervene("clarify", str(options[0]["ref"]))
                check(bool(result["ok"]), "legal clarification accepted")
                check(s.meeting_actions_left == before, "soft check preserves strong intervention/EMPATH")
                check(not bool(s.intervene("clarify", str(options[0]["ref"]))["ok"]), "same window cannot be farmed")
                for line in result.get("lines", []):
                    check(s.can_meeting_speak(str(line["speaker"])), "only active speakers")
                    check("{" not in str(line["text"]), "meeting formatted")
                    if str(line.get("thread_role", "")) == "response":
                        responses += 1
            s.meeting_continue()
        check(s.meeting_over(), "meeting terminates")
        check(s.current_packet() == packet, "checks do not change facts")
        for arc in s.stage_state().get("meeting_arcs", []):
            check(bool(arc["closed"]), "each argument closes before vote")
        s.advance()
        check(not s.final_statements().is_empty(), "last statements before ballot")
        check(not bool(s.intervene("clarify", "claim:mira")["ok"]), "no checks during vote")
    check(windows >= 14 and responses > 0, "real repeated windows with responses")

# 1.0: the task families have their own gate (tests/minigame_100_tests.gd).
func _mechanics() -> void:
    await process_frame

func _distance_motion() -> void:
    for id in AstraCrewCatalog.ORDER:
        var a := AstraPixelActor.new()
        a.setup(AstraPixelActor.crew_sheet(id), id, "", Color.WHITE)
        a.distance_driven = true
        a.set_moving(true)
        var frame := a._sprite.frame
        a._process(0.1)
        check(a._sprite.frame == frame, "stationary feet do not cycle")
        a.position.x += 25
        a._process(0.1)
        check(a._sprite.frame != frame, "distance advances gait")
        frame = a._sprite.frame
        a.face("left")
        check(a._sprite.frame == frame, "turn preserves contact phase")
        a.set_moving(false)
        a.talking = true
        a._process(0.2)
        check(a._sprite.sprite_frames.get_frame_texture(a._sprite.animation,a._sprite.frame) != null, "walk to talk never blank")
        a.free()
    for art in AstraExplorerCatalog.ART_IDS:
        var e := AstraPixelActor.new()
        e.setup(AstraPixelActor.player_sheet(art), "player", "", Color.WHITE)
        e.distance_driven = true
        e.set_moving(true)
        var seen := {}
        for step in range(16):
            e.position.x += 20
            e._process(0.05)
            seen[e._sprite.frame] = true
        check(seen.size() == 4, "explorer walk uses all four drawn frames: " + art)
        e.free()

# The six explorers are drawn by the user: every portrait, bust, head and pixel
# sheet exists and belongs to the same person, and identity changes voice.
func _art_and_voice() -> void:
    var arts := {}
    for id in AstraExplorerCatalog.ORDER:
        var d := AstraExplorerCatalog.data(id)
        var art := str(d["art_id"])
        check(not arts.has(art), "one pixel sheet per explorer")
        arts[art] = true
        check(art.begins_with(id), "pixel sheet is the explorer's own drawing: " + id)
        check(AstraExplorerCatalog.full_path(id) != "" and AstraExplorerCatalog.head_path(id) != "", "full figure and head: " + id)
        for mood in ["neutral", "smile", "shocked", "determined", "tired"]:
            check(AstraExplorerCatalog.bust_path(id, mood) != "", "bust %s/%s" % [id, mood])
        var full: Texture2D = load(AstraExplorerCatalog.full_path(id))
        check(full.get_height() == 1024 and full.get_width() < full.get_height(), "full figure is upright and uncropped: " + id)
        check(ResourceLoader.exists(AstraPixelActor.player_sheet(art)) and ResourceLoader.exists("res://assets/pixel080/player/%s_face.png" % art), "pixel sheet and face: " + id)
        check(AstraExplorerCatalog.MEETING_VOICE.has(id) and AstraExplorerCatalog.FIRST_CONTACT.get(id, {}).size() == 8, "meeting voice and a first contact with each crew member: " + id)
        for key in AstraExplorerCatalog.MEETING_VOICE[id]:
            check(str(AstraExplorerCatalog.MEETING_VOICE[id][key]).count("%s") == _placeholders(str(key)), "voice %s/%s keeps its placeholders" % [id, key])
    # Legacy art never maps to an explorer.
    for preset in AstraExplorerCatalog.LEGACY_ART:
        check(AstraExplorerCatalog.normalize({"preset": preset})["explorer_id"] == "neutral", "legacy look stays neutral: " + preset)
    # Same seed, different explorer: same truth, different first meeting words.
    var said := {}
    for id in AstraExplorerCatalog.ORDER:
        var s := AstraGameSession.new()
        s.setup("GLASS_GARDEN", 90210)
        s.set_player_profile(AstraExplorerCatalog.profile_for(id))
        AstraTestBots._finish_morning(s)
        s.advance()
        for npc_id in s.living_ids():
            if s.conversations_left() > 0:
                s.ask(str(npc_id), "STATEMENT")
        s.advance()
        var words := ""
        var guard := 0
        while not s.meeting_over() and guard < 10:
            guard += 1
            for option in s.clarification_options():
                var r := s.intervene("clarify", str(option["ref"]))
                for line in r.get("lines", []):
                    if str(line.get("speaker", "")) == "player":
                        words += str(line["text"])
                break
            s.meeting_continue()
        said[words] = true
    check(said.size() == 6, "six different meeting voices")

func _placeholders(key: String) -> int:
    return {"present": 1, "defend": 1, "compare": 3, "support": 1, "press": 1, "hearsay": 1, "clarify": 0, "coax": 1, "basis": 2, "link": 2}[key]
