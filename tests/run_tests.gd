extends SceneTree

# ASTRA 0.8.0 CONTAINMENT — main headless suite.
#   godot --headless --path . --script res://tests/run_tests.gd -- --games=40
# Rules, Day packets, fairness, vote/night/parity, knowledge limits, meeting
# moments, protocols, story/dialogue consistency, saves and bot balance.

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    var games := 40
    for arg in OS.get_cmdline_user_args():
        if str(arg).begins_with("--games="):
            games = int(str(arg).substr(8))
    if "--sim-only" in OS.get_cmdline_user_args():
        test_simulations(games)
        print("SIM DONE")
        quit(0)
        return
    test_josa()
    test_stage_structure()
    test_day_packets()
    test_session_flow()
    test_conversation()
    test_meeting_moments()
    test_vote_rules()
    test_night_and_survival()
    test_parity()
    test_knowledge_limits()
    test_protocols()
    test_story_consistency()
    test_dialogue_consistency()
    test_saves()
    test_meta_progress()
    test_simulations(games)
    if failures.is_empty():
        print("ASTRA TESTS OK · %d checks" % checks)
        quit(0)
    else:
        for failure in failures.slice(0, 60):
            printerr("FAIL · " + failure)
        printerr("ASTRA TESTS FAILED · %d of %d checks" % [failures.size(), checks])
        quit(1)

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)

func _finish_morning(s: AstraGameSession) -> void:
    AstraTestBots._finish_morning(s)

# ---------------------------------------------------------------- josa

func test_josa() -> void:
    check(AstraJosa.eun("미라") == "미라는", "josa 미라는")
    check(AstraJosa.eun("소렌") == "소렌은", "josa 소렌은")
    check(AstraJosa.i("의료실") == "의료실이", "josa 의료실이")
    check(AstraJosa.ro("의료실") == "의료실로", "josa 의료실로 (ㄹ)")
    check(AstraJosa.eul("라운지") == "라운지를", "josa 라운지를")
    check(AstraJosa.wa("다렌") == "다렌과", "josa 다렌과")
    check(AstraJosa.rang("준") == "준이랑" and AstraJosa.rang("노아") == "노아랑", "josa rang")
    check(AstraJosa.ieot("준") == "준이었" and AstraJosa.ieot("노아") == "노아였", "josa ieot")
    check(AstraJosa.iyo("기관실") == "기관실이요" and AstraJosa.iyo("라운지") == "라운지요", "josa iyo")
    check(AstraJosa.fill("{a|eul} 봤어요", {"a": "준"}) == "준을 봤어요", "fill token")
    check(AstraJosa.fill("{a|ira}고", {"a": "통신실"}) == "통신실이라고", "fill ira")
    check(AstraJosa.join_names(["미라", "노아", "다렌"]) == "미라, 노아와 다렌", "join names")

# ---------------------------------------------------------------- stages

func test_stage_structure() -> void:
    var expected_roster := {1: 4, 2: 5, 3: 6, 4: 7}
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        var stage := AstraCaseCatalog.stage_index(case_id)
        var data := AstraCaseCatalog.get_case(case_id)
        var roster: Array = AstraCaseCatalog.roster(data)
        var want := int(expected_roster.get(stage, 8))
        check(roster.size() == want, "%s roster %d (want %d)" % [case_id, roster.size(), want])
        check(AstraCaseCatalog.null_count(data) == (1 if stage < 5 else 2), "%s null count" % case_id)
        check(AstraCaseCatalog.part_for(case_id) == (1 if stage < 5 else 2), "%s part" % case_id)
        for id in roster:
            check(int(AstraCrewCatalog.JOIN_STAGE[id]) <= stage, "%s: %s joined by this Stage" % [case_id, id])
        var s := AstraGameSession.new()
        s.setup(case_id, 101 + stage)
        check(s.phase == "BRIEFING" and s.day == 1, "%s starts Day 1 morning" % case_id)
        check(s.available_protocols().is_empty() == (stage < 5), "%s protocols only in Part II" % case_id)
    var fresh := AstraGameSession.new()
    fresh.setup("CALIBRATION", 7)
    check(fresh.active_roster() == ["mira", "rho", "dax", "noa"], "fresh Stage 1 has exactly the four first crew")

# ---------------------------------------------------------------- day packets

func test_day_packets() -> void:
    var failures_seen := 0
    var total := 0
    var distorted := 0
    var hearsay := 0
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        var roster: Array = AstraCaseCatalog.roster(AstraCaseCatalog.get_case(case_id))
        for seed_value in range(1, 61):
            var truth := AstraCaseGenerator.generate(case_id, seed_value)
            var nulls: Array = truth.get("nulls", [])
            for day in [1, 2, 3]:
                var packet := AstraCaseGenerator.generate_day_packet(case_id, seed_value, day, roster, nulls)
                total += 1
                var issues := AstraCaseGenerator.validate_day_packet(packet, roster, nulls)
                if not issues.is_empty():
                    failures_seen += 1
                # Deterministic: the same inputs give the same packet.
                var again := AstraCaseGenerator.generate_day_packet(case_id, seed_value, day, roster, nulls)
                check(str(again.get("fragments", [])) == str(packet.get("fragments", [])), "%s/%d/D%d packet deterministic" % [case_id, seed_value, day])
                var fragments: Array = packet.get("fragments", [])
                check(fragments.size() >= 2 and fragments.size() <= 9, "%s/%d/D%d fragment count %d" % [case_id, seed_value, day, fragments.size()])
                for item in fragments:
                    var text := str(item.get("text", ""))
                    check(text.find("{") < 0 and text.find("|") < 0, "%s/%d text formatted: %s" % [case_id, seed_value, text])
                    check(not ("Null" in text or "무고" in text), "%s/%d no role leak in fragment" % [case_id, seed_value])
                    check(str(item.get("owner", "")) in roster, "%s/%d fragment owner awake" % [case_id, seed_value])
                    if str(item.get("type", "")) == "HEARSAY":
                        hearsay += 1
                        if bool(item.get("distorted", false)):
                            distorted += 1
                var benign: Dictionary = packet.get("benign", {})
                check(benign.is_empty() or str(benign.get("npc", "")) not in nulls, "%s/%d benign liar is innocent" % [case_id, seed_value])
    check(failures_seen <= int(total * 0.01), "fairness contract holds (%d of %d packets failed)" % [failures_seen, total])
    check(hearsay > 0 and distorted > 0, "retold sightings exist and some are distorted (%d/%d)" % [distorted, hearsay])

# ---------------------------------------------------------------- flow

func test_session_flow() -> void:
    var s := AstraGameSession.new()
    s.setup("DEAD_AIR", 4242)
    check(s.phase == "BRIEFING" and not s.story_finished(), "Day starts with the morning scene")
    check(not s.can_advance(), "morning must be read before the Day moves on")
    _finish_morning(s)
    check(s.can_advance(), "morning read → can advance")
    s.advance()
    check(s.phase == "INTERROGATION", "morning → conversation (no investigation phase)")
    check(s.conversations_max() >= 2 and s.conversations_max() <= 3, "2–3 conversations a Day")
    s.advance()
    check(s.phase == "MEETING", "conversation → meeting")
    s.advance()
    check(s.phase == "VOTE", "meeting → vote")
    check(not s.can_advance(), "cannot leave the vote without voting")
    s.cast_vote(str(s.eligible_vote_targets()[0]))
    if s.vote_stage() == "RUNOFF":
        s.cast_vote(str(s.runoff_candidates()[0]))
    if s.vote_stage() == "TIEBREAK":
        s.resolve_tiebreak(str(s.runoff_candidates()[0]))
    check(s.vote_cast and s.isolations.size() == 1, "exactly one isolation per Day")
    s.advance()
    check(s.phase in ["BRIEFING", "RESULT"], "Part I night resolves on its own")
    if s.phase == "BRIEFING":
        check(s.day == 2, "next Day begins")
        check(not s.story_finished(), "Day 2 opens with a morning scene")
    check("INVESTIGATION" not in AstraCaseCatalog.phase_flow("DEAD_AIR"), "phase flow has no investigation")

func test_conversation() -> void:
    var s := AstraGameSession.new()
    s.setup("GLASS_GARDEN", 9090)
    _finish_morning(s)
    s.advance()
    var first := str(s.living_ids()[0])
    var options := s.question_options(first)
    check(options.size() == 1 and str(options[0]["intent"]) == "STATEMENT", "a closed conversation offers only 'hear them out'")
    var result := s.ask(first, "STATEMENT")
    check(bool(result.get("ok", false)) and not Array(result.get("lines", [])).is_empty(), "statement produces lines")
    check(s.conversations_left() == s.conversations_max() - 1, "statement spends one conversation")
    options = s.question_options(first)
    check(options.size() >= 1 and options.size() <= 4, "follow-ups are few (%d)" % options.size())
    for option in options:
        check(str(option.get("label", "")) != "" and not str(option.get("label", "")).contains("{"), "option label formatted")
    var used := 0
    for npc_id in s.living_ids():
        if s.conversations_left() <= 0:
            break
        if s.ask(str(npc_id), "STATEMENT").get("ok", false):
            used += 1
    check(s.conversations_left() == 0, "conversation budget runs out")
    var extra := ""
    for npc_id in s.living_ids():
        if not s.conversation_open(str(npc_id)):
            extra = str(npc_id)
    if extra != "":
        check(not bool(s.ask(extra, "STATEMENT").get("ok", false)), "cannot open a conversation over budget")
    # A person's cabin is "my cabin" in their own mouth.
    var own := false
    for entry in s.transcripts.get(first, []):
        if s.name_of(first) + "의 선실" in str(entry.get("text", "")) and str(entry.get("speaker", "")) == first:
            own = true
    check(not own, "nobody calls their own cabin by their own name")

func test_meeting_moments() -> void:
    var s := AstraGameSession.new()
    s.setup("ECHO_WARD", 5151)
    _finish_morning(s)
    s.advance()
    s.advance()
    check(s.phase == "MEETING" and not s.meeting_feed.is_empty(), "meeting opens with lines")
    var options := s.meeting_options()
    check(options.size() >= 1 and options.size() <= 4, "2–3 moment options plus 'accuse' (%d)" % options.size())
    var accuse_last := str(options[options.size() - 1].get("kind", "")) == "accuse"
    check(accuse_last, "direct accusation is always last")
    var before := s.meeting_feed.size()
    s.meeting_continue()
    check(s.meeting_feed.size() >= before, "continuing the meeting plays on")
    var intervened := false
    for option in s.meeting_options():
        if str(option["kind"]) != "accuse":
            intervened = bool(s.intervene(str(option["kind"]), str(option["ref"])).get("ok", false))
            if intervened:
                break
    if not intervened:
        intervened = bool(s.intervene("accuse", str(s.living_ids()[0])).get("ok", false))
    check(intervened, "the explorer can intervene")
    check(s.meeting_actions_left == 0 and s.meeting_options().is_empty(), "one intervention per meeting without EMPATH")
    s._finish_meeting()
    check(s.meeting_over(), "the meeting ends")
    for entry in s.meeting_feed:
        var text := str(entry.get("text", ""))
        check(text.find("{") < 0, "meeting line formatted: " + text)
        check(not ("HARD_RECORD" in text or "NULL_DECEPTION" in text or "insufficient_evidence" in text), "no internal keys in meeting: " + text)

# ---------------------------------------------------------------- vote

func test_vote_rules() -> void:
    var ties := 0
    for seed_value in range(1, 41):
        var s := AstraGameSession.new()
        s.setup("SILENT_ORBIT", 3000 + seed_value, "GUARDIAN")
        _finish_morning(s)
        s.advance()
        s.advance()
        s.advance()
        check(not bool(s.cast_vote("").get("ok", false)), "abstention is refused")
        check(not bool(s.cast_vote("player").get("ok", false)), "cannot vote for the explorer")
        var target := str(s.eligible_vote_targets()[seed_value % s.eligible_vote_targets().size()])
        var result := s.cast_vote(target)
        check(bool(result.get("ok", false)), "legal vote accepted")
        var weight := 0
        for ballot in s.vote_ballots():
            if str(ballot.get("voter", "")) == "player":
                weight = int(ballot.get("weight", 0))
            check(str(ballot.get("target", "")) != "", "every voter names someone")
            if str(ballot.get("voter", "")) != "player":
                check(str(ballot.get("line", "")) != "" and str(ballot.get("line", "")).find("{") < 0, "ballot has a spoken line")
        check(weight == 1, "explorer's ballot weighs exactly one")
        if s.vote_stage() == "RUNOFF":
            ties += 1
            var pool := s.runoff_candidates()
            check(pool.size() >= 2, "runoff among the tied only")
            s.cast_vote(str(pool[0]))
        if s.vote_stage() == "TIEBREAK":
            var pool2 := s.runoff_candidates()
            check(bool(s.resolve_tiebreak(str(pool2[0])).get("ok", false)), "explorer decides a tied runoff")
        check(s.vote_cast and s.isolations.size() == 1, "exactly one isolation")
        var text := str(s.last_vote.get("isolation_text", "")) + str(s.last_vote.get("aftermath", []))
        check(not ("Null" in text and "이었다" in text) and "NULL" not in text, "isolation reveals no role")
    check(ties > 0, "deterministic vote fixtures exercise at least one runoff")

# ---------------------------------------------------------------- night

func test_night_and_survival() -> void:
    var s := AstraGameSession.new()
    s.setup("DEAD_AIR", 777)
    check(not s.night_needs_choice(), "Part I has no night menu")
    var g := AstraGameSession.new()
    g.setup("SILENT_ORBIT", 778, "GUARDIAN")
    check(g.protocol == "GUARDIAN" and g.guardian_charges() == 2, "Guardian starts with two Aegis charges")
    _finish_morning(g)
    g.advance()
    g.advance()
    g.advance()
    g.cast_vote(str(g.eligible_vote_targets()[0]))
    if g.vote_stage() == "RUNOFF":
        g.cast_vote(str(g.runoff_candidates()[0]))
    if g.vote_stage() == "TIEBREAK":
        g.resolve_tiebreak(str(g.runoff_candidates()[0]))
    if g.outcome == "":
        g.advance()
        check(g.phase == "NIGHT", "Guardian with a charge gets a night choice")
        check("player" in g.night_options().get("protect", []), "the explorer can shield themself")
        var res := g.choose_night_action("protect", "player")
        check(bool(res.get("ok", false)) and g.guardian_charges() == 1, "a charge is spent")
        for line in g.night_result.get("report", []):
            for id in g.living_null_ids():
                check(g.name_of(str(id)) + "|i" not in str(line), "Aegis report never names the attacker")
        check(g.stage_state()["guardian"]["last_target"] == "player", "last target remembered")
    # Player death ends the Stage at once.
    var d := AstraGameSession.new()
    d.setup("RED_SHIFT", 99)
    d.phase = "NIGHT"
    d.stage_state()["player_threat"] = {}
    for id in d.living_null_ids():
        d.stage_state()["player_threat"][id] = 99.0
    d._resolve_night()
    check(not d.player_alive() and d.outcome == "LOSE" and d.outcome_reason() == "player_killed", "explorer's death is an immediate loss")

func test_parity() -> void:
    var s := AstraGameSession.new()
    s.setup("SILENT_ORBIT", 4040)
    var innocents := s.living_crew_ids()
    for index in range(innocents.size()):
        if index >= innocents.size() - 1:
            break
        s.crew[innocents[index]].status = AstraCrewMember.STATUS_OFFLINE
    s._check_end("night")
    check(s.outcome == "LOSE" and s.outcome_reason() == "null_control", "parity counts living crew plus the explorer")
    var w := AstraGameSession.new()
    w.setup("CALIBRATION", 4041)
    for id in w.living_null_ids():
        w.crew[id].status = AstraCrewMember.STATUS_ISOLATED
    w._check_end("vote")
    check(w.outcome == "WIN", "isolating every Null wins")

# ---------------------------------------------------------------- knowledge

func test_knowledge_limits() -> void:
    var leaks := 0
    for seed_value in range(1, 31):
        var s := AstraGameSession.new()
        s.setup("GLASS_GARDEN", 600 + seed_value)
        for item in s.current_packet().get("fragments", []):
            var id := str(item.get("id", ""))
            for npc_id in s.living_ids():
                if str(npc_id) == str(item.get("owner", "")) or str(npc_id) == str(item.get("via", "")):
                    continue
                if AstraKnowledgeModel.knows(s.flags, str(npc_id), id):
                    leaks += 1
            if str(item.get("type", "")) == "SYSTEM_RECORD" and s.log_unread(id):
                check(not AstraKnowledgeModel.knows(s.flags, str(item.get("owner", "")), id), "an unopened log is nobody's knowledge yet")
        check(not AstraKnowledgeModel.knows(s.flags, "player", "claim:D1:" + str(s.living_ids()[0])), "explorer knows no claim before asking")
    check(leaks == 0, "fragments start known only to their holder (%d leaks)" % leaks)
    # A Null judges from public facts only.
    var n := AstraGameSession.new()
    n.setup("ECHO_WARD", 31)
    var null_id := str(n.living_null_ids()[0])
    var view := n.suspicion_breakdown(null_id, str(n.living_crew_ids()[0]), true)
    for reason in view.get("reasons", []):
        var src := str(reason.get("source", ""))
        var frag := n.fragment(src)
        if not frag.is_empty():
            check(AstraKnowledgeModel.is_public(n.flags, src), "Null reasoning used a private fragment")

# ---------------------------------------------------------------- protocols

func test_protocols() -> void:
    var p := AstraGameSession.new()
    p.setup("DEAD_AIR", 1, "GUARDIAN")
    check(p.protocol == "NONE", "no protocol in Part I")
    var legacy := AstraGameSession.new()
    legacy.setup("RED_SHIFT", 1, "AUDITOR")
    check(legacy.protocol == "ANALYST", "AUDITOR migrates to ANALYST where it exists")
    var legacy5 := AstraGameSession.new()
    legacy5.setup("SILENT_ORBIT", 1, "AUDITOR")
    check(legacy5.protocol in ["NONE", "GUARDIAN"], "AUDITOR never survives (%s)" % legacy5.protocol)
    # Stage 5 fits Aegis in the story; Stage 6+ offers a choice in a scene.
    var five := AstraGameSession.new()
    five.setup("SILENT_ORBIT", 2)
    var found_five := false
    for scene in five.story_queue():
        if str(scene.get("kind", "")) == "protocol":
            found_five = true
            check(Array(scene.get("choices", [])).is_empty(), "a single option is not a choice")
    check(found_five and five.protocol == "GUARDIAN", "Stage 5 fits the Aegis field in the story")
    var six := AstraGameSession.new()
    six.setup("RED_SHIFT", 3)
    var choice_scene := {}
    for scene in six.story_queue():
        if str(scene.get("kind", "")) == "protocol":
            choice_scene = scene
    check(Array(choice_scene.get("choices", [])).size() == 2, "Stage 6 chooses between two protocols in the story")
    var e := AstraGameSession.new()
    e.setup("LAST_LIGHT", 4, "EMPATH")
    _finish_morning(e)
    e.advance()
    var who := str(e.living_ids()[0])
    e.ask(who, "STATEMENT")
    var has_empathy := false
    for option in e.question_options(who):
        if str(option.get("intent", "")) == "EMPATHY":
            has_empathy = true
    check(has_empathy, "EMPATH offers one extra read")
    var a := AstraGameSession.new()
    a.setup("LAST_LIGHT", 5, "ANALYST")
    _finish_morning(a)
    a.advance()
    for npc_id in a.living_ids().slice(0, 2):
        a.ask(str(npc_id), "STATEMENT")
    var items := a.analyst_candidates()
    if items.size() >= 2:
        var r := a.analyst_compare(str(items[0]["ref"]), str(items[1]["ref"]))
        check(str(r.get("result", "")) in ["CONSISTENT", "CONFLICT", "INSUFFICIENT"], "ANALYST returns one of three verdicts")
        check(not a.analyst_available(), "ANALYST is once a Day")

# ---------------------------------------------------------------- story consistency (§79)

func test_story_consistency() -> void:
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        var stage := AstraCaseCatalog.stage_index(case_id)
        var roster: Array = AstraCaseCatalog.roster(AstraCaseCatalog.get_case(case_id))
        var not_yet: Array = []
        for id in AstraCrewCatalog.ORDER:
            if id not in roster:
                not_yet.append(id)
        for scene in AstraStageStory.opening(case_id):
            for line in scene.get("lines", []):
                var speaker := str(line[0])
                check(speaker == "" or speaker in roster, "%s opening speaker %s is awake" % [case_id, speaker])
                for id in not_yet:
                    check(AstraCrewCatalog.name_ko(id) not in str(line[1]), "%s opening mentions %s before they wake" % [case_id, id])
            check(str(scene.get("speaker_intro", "")) == "" or str(scene.get("speaker_intro", "")) in roster, "%s intro is in roster" % case_id)
        # Mornings after a death or isolation: nobody who is gone speaks.
        for seed_value in [11, 22, 33]:
            var s := AstraGameSession.new()
            s.setup(case_id, seed_value)
            var guard := 0
            while s.phase != "RESULT" and s.day < 3 and guard < 40:
                guard += 1
                match s.phase:
                    "BRIEFING":
                        for scene in s.story_queue():
                            for line in scene.get("lines", []):
                                var who := str(line[0])
                                check(who == "" or s.is_alive(who) or str(scene.get("kind", "")) in ["opening", "vignette"], "%s/%d D%d dead or isolated %s speaks in the morning" % [case_id, seed_value, s.day, who])
                                check(str(line[1]).find("{") < 0, "%s morning line formatted" % case_id)
                        _finish_morning(s)
                        s.advance()
                    "VOTE":
                        s.cast_vote(str(s.eligible_vote_targets()[0]))
                        if s.vote_stage() == "RUNOFF": s.cast_vote(str(s.runoff_candidates()[0]))
                        if s.vote_stage() == "TIEBREAK": s.resolve_tiebreak(str(s.runoff_candidates()[0]))
                        s.advance()
                    "NIGHT":
                        s.choose_night_action("skip", "")
                        s.advance()
                    "MEETING":
                        s._finish_meeting()
                        for entry in s.meeting_feed:
                            var sp := str(entry.get("speaker", ""))
                            check(sp in ["", "player"] or s.is_alive(sp), "%s meeting speaker %s is active" % [case_id, sp])
                        s.advance()
                    _:
                        s.advance()
        check(stage >= 1, "stage index")

# ---------------------------------------------------------------- dialogue consistency (§80)

const SUPPORTED_TOKENS := ["", "eun", "i", "eul", "wa", "ro", "a", "ira", "ida", "iya", "ieyo", "rang", "ieot", "iyo"]
const SESSION_KEYS := ["open_with", "open_alone", "saw_specific", "saw_group", "saw_none", "deny", "opinion", "opinion_none",
    "m_accuse", "m_agree", "m_caution", "m_defend_self", "m_defend_alone", "m_vouch", "m_vouch_character", "m_saw", "m_record",
    "m_record_other", "m_excuse_again", "m_settle", "m_hold_sighting", "m_basis", "m_basis_thin", "m_note_thin", "m_retreat",
    "vote_evidence", "vote_follow", "vote_player", "vote_unsure", "last_plea", "last_plea_secret", "after_isolation",
    "after_isolation_close", "open_after_accused", "open_after_defended", "habit", "record_open", "record_open_other",
    "m_benign_callout", "m_benign_callout_self", "partial_admit", "confess", "deflect", "vote_lean", "hint_record_other",
    "record_meaning_other", "record_meaning_specific_other", "m_defend_alone"]

func test_dialogue_consistency() -> void:
    for npc_id in AstraCrewCatalog.ORDER:
        for key in SESSION_KEYS:
            check(AstraSocialLines.line(npc_id, str(key), {}, 0.1) != "", "line %s exists for %s" % [key, npc_id])
    for table in [AstraSocialLines.LINES, AstraSocialLines.MORE, AstraSocialLines.MORE2, AstraSocialLines.RECORD_OTHER]:
        for npc_id in table:
            check(npc_id in AstraCrewCatalog.ORDER, "known character id " + str(npc_id))
            for key in table[npc_id]:
                var seen := {}
                for text in table[npc_id][key]:
                    var line := str(text)
                    check(line.strip_edges() != "", "%s/%s non-empty" % [npc_id, key])
                    check(not seen.has(line), "%s/%s no duplicate line" % [npc_id, key])
                    seen[line] = true
                    for internal in ["HARD_RECORD", "NULL_DECEPTION", "EXPERT_INFERENCE", "insufficient_evidence", "DIRECT_WITNESS", "_"]:
                        check(internal not in line, "%s/%s internal text: %s" % [npc_id, key, line])
                    var cursor := 0
                    while true:
                        var open := line.find("{", cursor)
                        if open < 0:
                            break
                        var close := line.find("}", open)
                        check(close > open, "%s/%s balanced token" % [npc_id, key])
                        if close < 0:
                            break
                        var token := line.substr(open + 1, close - open - 1)
                        var bar := token.find("|")
                        var particle := token.substr(bar + 1) if bar >= 0 else ""
                        check(particle in SUPPORTED_TOKENS, "%s/%s supported josa token {%s}" % [npc_id, key, token])
                        cursor = close + 1
    for npc_id in AstraCrewCatalog.ORDER:
        var persona := AstraCrewCatalog.persona(npc_id)
        for axis in ["speech", "judgement", "need", "under_pressure", "flaw", "contradiction", "habit"]:
            check(str(persona.get(axis, "")) != "", "%s persona axis %s" % [npc_id, axis])
        check(AstraCrewCatalog.SPOTLIGHT.has(npc_id) and not Array(AstraCrewCatalog.SPOTLIGHT[npc_id].get("major", [])).is_empty(), "%s has a major spotlight Stage" % npc_id)
    # Voices: banmal speakers never end on polite endings in their own lines.
    for npc_id in ["rho", "dax", "sena", "eli"]:
        for key in ["m_basis", "vote_evidence", "vote_follow", "m_vouch_character"]:
            var line := AstraSocialLines.line(npc_id, key, {"target": "미라", "reason": "말을 바꾼 점", "pusher": "노아"}, 0.1)
            check(not line.ends_with("요.") and not line.ends_with("요?"), "%s keeps banmal in %s: %s" % [npc_id, key, line])

# ---------------------------------------------------------------- saves

func test_saves() -> void:
    var path := "user://astra_test_080.cfg"
    var s := AstraGameSession.new()
    s.setup("SILENT_ORBIT", 5050, "GUARDIAN")
    _finish_morning(s)
    s.advance()
    s.ask(str(s.living_ids()[0]), "STATEMENT")
    s.advance()
    check(s.save_snapshot(path), "snapshot saves mid-meeting")
    var r := AstraGameSession.new()
    check(r.load_snapshot(path), "snapshot loads")
    check(r.phase == "MEETING" and r.day == s.day and r.case_id == s.case_id, "phase/day/stage restored")
    check(r.protocol == "GUARDIAN" and r.guardian_charges() == 2, "protocol and charges restored")
    check(r.meeting_feed.size() == s.meeting_feed.size(), "meeting feed restored")
    check(r.null_style(str(r.living_null_ids()[0])) == s.null_style(str(s.living_null_ids()[0])), "Null style stays stable")
    r._finish_meeting()
    r.advance()
    check(r.phase == "VOTE", "restored game keeps playing")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))

func test_meta_progress() -> void:
    var path := "user://astra_test_meta_080.cfg"
    var meta := AstraMetaProgress.new(path)
    check(meta.is_case_unlocked_for_slot("CALIBRATION", 1), "Stage 1 always open")
    check(not meta.is_case_unlocked_for_slot("DEAD_AIR", 1), "a fresh slot starts at Stage 1")
    check(AstraUnlocks.has(meta.unlocked_features(), "meeting"), "core meeting feature available")

    # ATTEMPTED is statistics only. A loss must never become campaign progress.
    meta.calibration_completed = true
    meta.record_case_result("DEAD_AIR", "NONE", {"outcome": "LOSE"}, false)
    check(int(meta.case_counts.get("DEAD_AIR", 0)) == 1, "a loss is retained as an attempt")
    check(int(meta.case_wins.get("DEAD_AIR", 0)) == 0, "a loss is not a clear")
    check(not meta.is_case_unlocked("GLASS_GARDEN"), "global archive cannot unlock the next Stage from a loss")
    check(meta.completed_campaign_cases() == 0 and not meta.campaign_complete(), "campaign completion counts clears, not attempts")

    meta.record_case_result("DEAD_AIR", "NONE", {"outcome": "WIN"}, false)
    check(int(meta.case_wins.get("DEAD_AIR", 0)) == 1, "a win records a clear")
    check(meta.is_case_unlocked("GLASS_GARDEN"), "a real clear unlocks the next historical replay")

    var slot0 := {"chapters": ["CALIBRATION", "DEAD_AIR"]}
    meta.set_voyage_memory_for_slot(0, slot0)
    check(meta.is_case_unlocked_for_slot("GLASS_GARDEN", 0), "slot clear opens its next Stage")
    check(not meta.is_case_unlocked_for_slot("GLASS_GARDEN", 1), "another slot never inherits that clear")
    check(not meta.deep_unlocked(), "attempts and early clears never unlock Deep")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

# ---------------------------------------------------------------- balance (§1–§3)

func test_simulations(games: int) -> void:
    var totals := {"smart": 0, "random": 0, "passive": 0}
    var part2 := {"smart": 0, "random": 0, "passive": 0}
    var n := 0
    var n2 := 0
    var delta := {"smart_public": 0, "passive_public": 0, "smart_shifts": 0, "smart_confessions": 0}
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        var stage := AstraCaseCatalog.stage_index(case_id)
        var proto := "GUARDIAN" if stage >= 5 else "NONE"
        var w := {"smart": 0, "random": 0, "passive": 0}
        for index in range(games):
            var seed_value := 1000 + index * 13
            var smart := AstraTestBots.play_smart(case_id, seed_value, proto)
            var random := AstraTestBots.play_random(case_id, seed_value, proto)
            var passive := AstraTestBots.play_passive(case_id, seed_value)
            check(not smart.is_empty() and not random.is_empty() and not passive.is_empty(), "%s/%d games finish" % [case_id, seed_value])
            if str(smart.get("outcome", "")) == "WIN": w["smart"] += 1
            if str(random.get("outcome", "")) == "WIN": w["random"] += 1
            if str(passive.get("outcome", "")) == "WIN": w["passive"] += 1
            var ss: Dictionary = smart.get("stats", {})
            var ps: Dictionary = passive.get("stats", {})
            delta["smart_public"] += int(ss.get("presented", 0)) + int(ss.get("public_contradictions", 0))
            delta["passive_public"] += int(ps.get("presented", 0)) + int(ps.get("public_contradictions", 0))
            delta["smart_confessions"] += int(ss.get("confessions", 0)) + int(ss.get("admissions", 0))
        for k in w:
            totals[k] += w[k]
            if stage >= 5:
                part2[k] += w[k]
        n += games
        if stage >= 5:
            n2 += games
        print("%-18s smart %3d%% random %3d%% passive %3d%%" % [case_id, 100 * w["smart"] / games, 100 * w["random"] / games, 100 * w["passive"] / games])
    var smart_rate := float(totals["smart"]) / float(n)
    var random_rate := float(totals["random"]) / float(n)
    var passive_rate := float(totals["passive"]) / float(n)
    print("TOTAL smart %d%% · random %d%% · passive %d%% · PART II smart %d%% passive %d%%" % [int(smart_rate * 100), int(random_rate * 100), int(passive_rate * 100), 100 * part2["smart"] / maxi(1, n2), 100 * part2["passive"] / maxi(1, n2)])
    print("CONTRIBUTION smart public facts %.2f/game vs passive %.2f/game · secrets+admissions %.2f/game" % [float(delta["smart_public"]) / n, float(delta["passive_public"]) / n, float(delta["smart_confessions"]) / n])
    # 0.8.0 gates (see docs/QA_REPORT.md for why these replace the 0.7.x
    # "passive < 20%" rule, which measured an abstain bot that no longer exists):
    #  - a thinking player wins most Stages without guessing;
    #  - a thinking player clearly beats both random and carried play;
    #  - the explorer's actions put facts on the table the room would not.
    check(smart_rate >= 0.75, "a thinking player wins most Stages (%.0f%%)" % (smart_rate * 100))
    check(smart_rate >= random_rate + 0.1, "thinking beats random (%.0f%% vs %.0f%%)" % [smart_rate * 100, random_rate * 100])
    check(smart_rate >= passive_rate + 0.05, "thinking beats being carried (%.0f%% vs %.0f%%)" % [smart_rate * 100, passive_rate * 100])
    check(float(part2["passive"]) / float(maxi(1, n2)) <= 0.85, "Part II does not carry a passive player (%.0f%%)" % (100.0 * part2["passive"] / maxi(1, n2)))
    check(delta["smart_public"] > delta["passive_public"] * 2, "the explorer's play changes what is public")
