extends SceneTree

# 1.0 deduction gate: the explorer's link verb, the room's answers, the
# meeting board and closing, the reasoned ballot, the "raised aloud" rule,
# the rewind, and the explorer selection screen.
#   godot --headless --path . --script res://tests/deduction_100_tests.gd

var checks := 0
var failures: Array = []
var tally := {}

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        print("FAIL · " + label)

func count(key: String) -> void:
    tally[key] = int(tally.get(key, 0)) + 1

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    for case_id in ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD", "SILENT_ORBIT"]:
        for seed in range(1, 13):
            _meeting_fixture(case_id, seed * 131 + 7)
    check(int(tally.get("contradiction", 0)) >= 20, "links that hold are common (%d)" % int(tally.get("contradiction", 0)))
    check(int(tally.get("equivalent", 0)) >= 3, "logically equivalent evidence is accepted for the same statement (%d)" % int(tally.get("equivalent", 0)))
    check(int(tally.get("innocent_target", 0)) >= 1, "a link can hold against an innocent's words (content, not roles) (%d)" % int(tally.get("innocent_target", 0)))
    check(int(tally.get("irrelevant", 0)) >= 10, "irrelevant pairings are refused with a reason (%d)" % int(tally.get("irrelevant", 0)))
    check(int(tally.get("clarify_kinds", 0)) >= 4, "clarifying questions vary with the point on the table (%d kinds)" % int(tally.get("clarify_kinds", 0)))
    check(int(tally.get("narrows_pair", 0)) + int(tally.get("intersection", 0)) >= 3, "two independent sources can be combined (%d)" % (int(tally.get("narrows_pair", 0)) + int(tally.get("intersection", 0))))
    _raised_rule()
    _lone_conviction()
    _rewind()
    await _selection()
    print("DEDUCTION TALLY %s" % str(tally))
    if failures.is_empty():
        print("ASTRA DEDUCTION 100 TESTS OK · %d checks" % checks)
        quit()
    else:
        print("ASTRA DEDUCTION 100 TESTS FAILED · %d/%d" % [failures.size(), checks])
        quit(1)

var _clarify_seen := {}

func _meeting_fixture(case_id: String, seed: int) -> void:
    var s := AstraGameSession.new()
    s.setup(case_id, seed, "GUARDIAN" if AstraCaseCatalog.stage_index(case_id) >= 5 else "NONE")
    AstraTestBots._finish_morning(s)
    s.advance()
    for npc_id in s.living_ids():
        if s.conversations_left() <= 0:
            break
        s.ask(str(npc_id), "STATEMENT")
        for option in s.question_options(str(npc_id)):
            if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["RECORD", "WITNESS"] and s.followups_left(str(npc_id)) > 0:
                s.ask(str(npc_id), str(option["intent"]), str(option.get("ref", "")))
    s.advance()
    check(s.phase == "MEETING", "%s/%d: in the meeting" % [case_id, seed])
    # Every pairing the explorer could make is judged; nothing crashes.
    var holds_by_statement := {}
    for statement in s.link_statements():
        var sref := str(statement["ref"])
        var evidence := s.link_evidence(sref)
        for ev in evidence:
            var eref := str(ev["ref"])
            check(eref.begins_with("claim:") or eref.begins_with("earlier:") or s.player_knows(eref), "link evidence is only what the explorer knows")
            var verdict := s.judge_link(sref, eref)
            var result := str(verdict["result"])
            check(result in ["CONTRADICTION", "NARROWS", "SUPPORT", "HEARSAY_ONLY", "SAME_SOURCE", "ALREADY_EXPLAINED", "UNCLEAR", "IRRELEVANT"], "a known verdict (%s)" % result)
            check(str(verdict["why"]) != "" and "|" not in str(verdict["why"]) and "{" not in str(verdict["why"]), "every verdict says why, formatted")
            if result == "CONTRADICTION":
                count("contradiction")
                holds_by_statement[sref] = int(holds_by_statement.get(sref, 0)) + 1
                for target in verdict["targets"]:
                    if not s.crew[str(target)].is_null():
                        count("innocent_target")
            elif result == "IRRELEVANT":
                count("irrelevant")
            if result == "NARROWS" and str(ev.get("kind", "")) == "fragment":
                for ev2 in evidence:
                    if str(ev2["ref"]) != eref and str(ev2.get("kind", "")) == "fragment":
                        var pair := s.judge_link(sref, eref, str(ev2["ref"]))
                        if str(pair["result"]) == "CONTRADICTION" and str(pair["family"]) == "intersection":
                            count("intersection")
                        elif str(pair["result"]) == "NARROWS" and Array(pair["targets"]).size() < Array(verdict["targets"]).size():
                            count("narrows_pair")
    for sref in holds_by_statement:
        if int(holds_by_statement[sref]) >= 2:
            count("equivalent")
    # Play the meeting: clarify when offered, make one holding link and one
    # irrelevant one, then let it close.
    var link := AstraTestBots.smart_link(s)
    var guard := 0
    while not s.meeting_over() and guard < 12:
        guard += 1
        for option in s.clarification_options():
            _clarify_seen[str(option["ref"]).get_slice(":", 0)] = true
        var soft := s.clarification_options()
        if not soft.is_empty():
            var start := s.meeting_feed.size()
            check(bool(s.intervene("clarify", str(soft[0]["ref"])).get("ok", false)), "a clarifying question is accepted")
            check(s.meeting_feed.size() > start + 1, "a clarifying question gets an answer")
        if link != "" and s.meeting_actions_left > 0:
            var start2 := s.meeting_feed.size()
            var trust_before := _trust(s)
            var result := s.intervene("link", link)
            check(bool(result.get("ok", false)), "a holding link is accepted")
            var lines: Array = s.meeting_feed.slice(start2)
            var speakers := {}
            for line in lines:
                speakers[str(line.get("speaker", ""))] = true
                check(s.can_meeting_speak(str(line.get("speaker", ""))), "only active people answer a link")
            var entry: Dictionary = s.stage_state().get("links", []).back()
            for target in entry.get("targets", []):
                if s.is_alive(str(target)):
                    check(speakers.has(str(target)) or _silent(lines, str(target)), "the person whose words were taken up answers (or visibly does not)")
            check(speakers.size() >= 3, "a link is a small exchange, not one line")
            check(_trust(s) >= trust_before - 0.001, "a link that holds costs no trust")
            link = ""
        s.meeting_continue()
    tally["clarify_kinds"] = _clarify_seen.size()
    check(s.meeting_over(), "the meeting closes")
    var closing_found := false
    for line in s.meeting_feed:
        closing_found = closing_found or str(line.get("text", "")).begins_with("여기까지 확인한 말로")
    check(closing_found and not s.meeting_summary().is_empty(), "the meeting closes with a plain summary before the vote")
    for line in s.meeting_summary():
        check("%" not in str(line) and "{" not in str(line), "the summary shows no numbers or tokens")
    s.advance()
    check(s.phase == "VOTE", "the vote follows the meeting")
    check(not s.final_statements().is_empty(), "final words before the ballot")
    var target := str(s.eligible_vote_targets()[0])
    var reasons := s.ballot_reasons(target)
    check(not reasons.is_empty() and str(reasons.back()["code"]) == "instinct", "the ballot offers known reasons and plain instinct")
    check(s.set_ballot_reason(target, 0), "the explorer's reason is recorded")
    check(str(s.ballot_reason().get("target", "")) == target, "the reason is kept with the Day")
    s.cast_vote(target)
    for ballot in s.vote_ballots():
        if str(ballot.get("voter", "")) != "player":
            check(str(ballot.get("line", "")) != "", "every NPC ballot says why, in words")

func _silent(lines: Array, target: String) -> bool:
    for line in lines:
        if str(line.get("speaker", "")) == "" and target != "" and "대답하지 않는다" in str(line.get("text", "")):
            return true
    return false

func _trust(s: AstraGameSession) -> float:
    var total := 0.0
    for id in s.living_ids():
        total += s.crew[id].trust
    return total

# Two alibis that cannot both be true only weigh with the room once someone
# has said so aloud; the explorer always sees them.
func _raised_rule() -> void:
    var found := false
    for seed in range(1, 60):
        var s := AstraGameSession.new()
        s.setup("GLASS_GARDEN", seed * 17 + 3)
        AstraTestBots._finish_morning(s)
        s.advance()
        s.advance()
        s._make_claims_public()
        var ids := s.living_ids()
        for i in range(ids.size()):
            for j in range(i + 1, ids.size()):
                var a := str(ids[i])
                var b := str(ids[j])
                if s._conflict_raised(a, b) or s._visible_conflict(a, s._claim_visible("", a), b, s._claim_visible("", b)) == "":
                    continue
                var observer := ""
                for o in ids:
                    if str(o) != a and str(o) != b and not s.crew[str(o)].is_null():
                        observer = str(o)
                        break
                if observer == "":
                    continue
                var before := _has_contradiction(s.suspicion_breakdown(observer, a), b)
                s._raise_pair(a, b)
                var after := _has_contradiction(s.suspicion_breakdown(observer, a), b)
                check(not before and after, "an unraised board conflict weighs only after it is said aloud")
                found = true
                break
            if found:
                break
        if found:
            break
    check(found, "a raised-conflict fixture exists")

func _has_contradiction(view: Dictionary, other: String) -> bool:
    for reason in view.get("reasons", []):
        if str(reason.get("source", "")) == "claim:" + other:
            return true
    return false

func _lone_conviction() -> void:
    var gated := 0
    for seed in range(1, 80):
        var s := AstraGameSession.new()
        s.setup("ECHO_WARD", seed * 7 + 1)
        AstraTestBots._finish_morning(s)
        s.advance()
        for npc_id in s.living_ids():
            var target := str(s.top_suspect_of(str(npc_id)).get("target", ""))
            if target != "" and s._lone_private_conviction(str(npc_id), target):
                gated += 1
                # once the explorer has heard it from them, they stand behind it
                for item in s.current_packet().get("fragments", []):
                    if str(item.get("owner", "")) == str(npc_id):
                        AstraKnowledgeModel.share_with(s.flags, str(item.get("id", "")), "player", s.day, str(npc_id))
                check(not s._lone_private_conviction(str(npc_id), target), "a private glimpse the explorer heard can be said aloud")
    check(gated >= 1, "a lone private glimpse is kept to a vote, not an accusation (%d)" % gated)

func _rewind() -> void:
    var path := "user://deduction100_dawn.session"
    var s := AstraGameSession.new()
    s.setup("GLASS_GARDEN", 4321)
    check(s.save_snapshot(path), "a morning can be saved")
    AstraTestBots._finish_morning(s)
    s.advance()
    for npc_id in s.living_ids():
        if s.conversations_left() > 0:
            s.ask(str(npc_id), "STATEMENT")
    s.outcome = "LOSE"
    s.stage_state()["outcome_reason"] = "player_killed"
    var memory := s.rewind_memory()
    check(not Array(memory.get("notes", [])).is_empty(), "the explorer takes notes of what they heard back")
    var restored := AstraGameSession.new()
    check(restored.load_snapshot(path), "the morning loads")
    var packet_before := restored.current_packet().duplicate(true)
    var known_before := restored.known_fragments().size()
    restored.apply_rewind(memory, 1)
    check(restored.rewinds_used() == 1 and not restored.rewind_notes().is_empty(), "the rewind is recorded with its memories")
    check(restored.current_packet() == packet_before and restored.truth == s.truth, "the same truth after a rewind")
    var echo := false
    for scene in restored.story_queue():
        echo = echo or str(scene.get("id", "")).begins_with("rewind_")
    check(echo, "the morning opens with the explorer's memory")
    for id in Array(memory.get("leads", [])):
        if restored.is_alive(str(id)):
            check(restored.talk_leads().has(str(id)) or restored.talk_leads().size() >= 4, "people remembered are marked to ask again")
    check(restored.known_fragments().size() == known_before, "remembered things are not knowledge: nothing new is known before asking")

func _selection() -> void:
    for resolution in [Vector2i(1366, 768), Vector2i(1920, 1080)]:
        root.size = resolution
        for id in AstraExplorerCatalog.ORDER:
            var setup := AstraPlayerSetup.new()
            root.add_child(setup)
            setup.setup(AstraExplorerCatalog.profile_for(id))
            await process_frame
            await process_frame
            check(setup.find_children("*", "AstraPixelActor", true, false).is_empty(), "no pixel character on the selection screen")
            var pixel := false
            for node in setup.find_children("*", "TextureRect", true, false):
                var tex: Texture2D = (node as TextureRect).texture
                if tex is AtlasTexture:
                    tex = (tex as AtlasTexture).atlas
                if tex != null and tex.resource_path.contains("pixel080"):
                    pixel = true
            check(not pixel, "no pixel texture on the selection screen")
            check(setup._figure.texture != null and setup._figure.texture.resource_path.contains("/explorers/%s/full" % id), "the main illustration of the selected explorer (%s)" % id)
            var card_tex = (setup._cards[id].find_children("*", "TextureRect", true, false)[0] as TextureRect).texture
            check(card_tex is AtlasTexture and (card_tex as AtlasTexture).atlas.resource_path.contains("/explorers/%s/full" % id), "the card is a crop of the same main illustration")
            var screen := Rect2(Vector2.ZERO, Vector2(resolution))
            for card in setup._cards.values():
                check(screen.encloses((card as Control).get_global_rect()), "card inside the screen at %d" % resolution.x)
            var start: Control = setup.find_child("StartButton", true, false)
            check(start != null and screen.encloses(start.get_global_rect()), "start button inside the screen at %d" % resolution.x)
            var got := {}
            setup.confirmed.connect(func(p): got["p"] = p)
            (start as Button).pressed.emit()
            check(str(Dictionary(got.get("p", {})).get("explorer_id", "")) == id, "confirming starts with the selected explorer")
            setup.queue_free()
            await process_frame
