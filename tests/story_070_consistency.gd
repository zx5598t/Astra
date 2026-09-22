extends SceneTree
# 0.7.0 story contract for ACT II (Day 8-13): each new chapter carries the
# same fields/uniqueness guarantees Act I's story_consistency_tests.gd
# requires, its "fact" is one of the 8 shared investigation-point tags (the
# exact bug that made goal_done unreachable during this version's own
# development — see case_catalog.gd/voyage_content.gd commit history), and
# every canon-protected mandatory reveal (§5, §36) is actually present in
# the authored text, not just asserted in a commit message.

var failures: Array[String] = []
var checks := 0

const ACT1_IDS := ["CALIBRATION","DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]
const ACT2_IDS := ["SECOND_WATCH","BORROWED_DAYS","BLIND_DECK","THREE_MINUTES_DARK","CONTINUITY","THRESHOLD"]
const VALID_FACTS := ["power","signal","destination","security","archive","arrival","everyday","sample"]

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func _initialize() -> void:
    test_chapter_fields()
    test_fact_tags_are_reachable()
    test_resolution_beats_shape()
    test_act_derivation()
    test_required_reveals_present()
    test_campaign_registration()
    if failures.is_empty():
        print("ASTRA STORY 070 CONSISTENCY TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures:
        printerr("FAIL · " + failure)
    quit(1)

func test_chapter_fields() -> void:
    var resolved_lines: Array[String] = []
    for case_id in ACT1_IDS + ACT2_IDS:
        var chapter := AstraVoyageContent.chapter(case_id)
        for key in ["situation","goal","discovery","resolved","open_question","outro","next_hook","fact"]:
            check(str(chapter.get(key,"")).strip_edges() != "","%s: story framing has %s" % [case_id,key])
        var resolved := str(chapter.get("resolved",""))
        check(resolved not in resolved_lines,"%s: local answer is chapter-specific" % case_id)
        resolved_lines.append(resolved)
        check(resolved != str(chapter.get("open_question","")),"%s: answer and remaining question differ" % case_id)
        check(str(chapter.get("open_question","")).count("?") <= 1,"%s: one major residual question budget" % case_id)

func test_fact_tags_are_reachable() -> void:
    # Regression guard: AstraVoyageContent.ROOMS is a fixed, shared pool of
    # investigation points with exactly these 8 fact tags. A chapter whose
    # "fact" is anything else can never set goal_done — this is the exact bug
    # found and fixed during 0.7.0 development.
    for case_id in ACT2_IDS:
        var fact := str(AstraVoyageContent.chapter(case_id).get("fact",""))
        check(fact in VALID_FACTS,"%s: fact '%s' is one of the shared investigation-point tags" % [case_id,fact])
    # Also confirm every declared fact actually appears on at least one point
    # somewhere in the room pool, independent of stage-gating.
    var seen_facts := {}
    for room_id in AstraVoyageContent.ROOMS:
        for point in AstraVoyageContent.ROOMS[room_id].get("points",[]):
            seen_facts[str(point[4])] = true
    for fact in VALID_FACTS:
        check(seen_facts.get(fact,false),"'%s' appears on at least one room point" % fact)

func test_resolution_beats_shape() -> void:
    for case_id in ACT2_IDS:
        var beat: Dictionary = AstraVoyageContent.RESOLUTION_BEATS.get(case_id,{})
        check(not beat.is_empty(),"%s has a RESOLUTION_BEATS entry" % case_id)
        check(str(beat.get("payoff_type","")) in ["FACTUAL","HUMAN","REALITY_CONTRADICTION"],"%s: valid payoff_type" % case_id)
        check(beat.get("participants",[]).size() >= 2,"%s: at least two participants" % case_id)
        check(beat.get("lines",[]).size() >= 3,"%s: resolution has room to breathe (>=3 lines)" % case_id)
        var choices: Array = beat.get("choices",[])
        check(choices.size() == 3,"%s: three handling choices" % case_id)
        var tags := {}
        for choice in choices:
            var tag := str(choice.get("memory_tag",""))
            check(tag != "" and not tags.has(tag),"%s: unique, non-empty memory_tag" % case_id)
            tags[tag] = true
            check(AstraVoyageContent.RESOLUTION_REACTIONS.has(tag),"%s: memory_tag '%s' has a RESOLUTION_REACTIONS entry" % [case_id,tag])

func test_act_derivation() -> void:
    for case_id in ACT1_IDS:
        check(AstraVoyageContent.act_for(case_id) == 1,"%s is ACT I" % case_id)
    for case_id in ACT2_IDS:
        check(AstraVoyageContent.act_for(case_id) == 2,"%s is ACT II" % case_id)
    check(AstraVoyageContent.act_for("CALIBRATION") == 1,"CALIBRATION is ACT I")

func _text_for(case_id: String) -> String:
    var chapter := AstraVoyageContent.chapter(case_id)
    var beat: Dictionary = AstraVoyageContent.RESOLUTION_BEATS.get(case_id,{})
    var text := str(chapter.get("situation","")) + str(chapter.get("resolved","")) + str(chapter.get("discovery","")) + str(chapter.get("outro",""))
    for line in beat.get("lines",[]):
        text += str(line[1])
    return text

func test_required_reveals_present() -> void:
    # §5/§36: every canon-protected mandatory reveal must actually be in the
    # authored text somewhere, not just implied. Substring checks against the
    # actual authored Korean, not a translation gloss.
    check(_text_for("DEAD_AIR").contains("원본"),"DEAD_AIR: dual destination documents both original")
    check(_text_for("ECHO_WARD").contains("목소리"),"ECHO_WARD: future/self voice reveal present")
    check(_text_for("SILENT_ORBIT").contains("19년"),"SILENT_ORBIT: ~19 year prior arrival present")
    check(_text_for("RED_SHIFT").contains("채집") and _text_for("RED_SHIFT").contains("출항"),"RED_SHIFT: pre-departure sample collection present")
    check(_text_for("LAST_LIGHT").contains("history") or _text_for("LAST_LIGHT").contains("사본"),"LAST_LIGHT: parallel histories present")
    check(_text_for("SECOND_WATCH").contains("근무") or _text_for("SECOND_WATCH").contains("일지"),"SECOND_WATCH: post-arrival duty log present")
    check(_text_for("CONTINUITY").contains("평범") or _text_for("CONTINUITY").contains("일상"),"CONTINUITY: ordinary post-arrival life present")
    check(_text_for("THRESHOLD").contains("장기수면") and _text_for("THRESHOLD").contains("다시"),"THRESHOLD: second long sleep implication present")
    # Canon must NOT be prematurely closed: no chapter should declare a final
    # single culprit/cause in its resolved/open_question text.
    for case_id in ACT1_IDS + ACT2_IDS:
        var chapter := AstraVoyageContent.chapter(case_id)
        var resolved := str(chapter.get("resolved",""))
        check(not resolved.contains("Null이 모든") and not resolved.contains("범인은"),"%s: does not prematurely close the mystery" % case_id)

func test_campaign_registration() -> void:
    check(AstraCaseCatalog.CAMPAIGN.size() == 12,"campaign has 12 post-calibration cases")
    for case_id in ACT2_IDS:
        check(case_id in AstraCaseCatalog.CAMPAIGN,"%s registered in CAMPAIGN" % case_id)
        check(AstraCaseCatalog.has_case(case_id),"%s has a CASES entry" % case_id)
        check(AstraVoyageContent.campaign_day(case_id) >= 8,"%s is Day 8 or later" % case_id)
    check(AstraCaseCatalog.CAMPAIGN.find("LAST_LIGHT") < AstraCaseCatalog.CAMPAIGN.find("SECOND_WATCH"),"LAST_LIGHT precedes SECOND_WATCH in campaign order")
