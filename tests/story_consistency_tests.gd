extends SceneTree
# 0.6.0 story contract: facts are experienced in play, Results only recap them,
# awakened participants stay chapter-correct, and each chapter solves one local
# question while handing one deeper question forward.

var failures: Array[String] = []
var checks := 0

const RETIRED_NAMES := ["Ives", "Orin", "Sael", "Tess", "Ren", "Ari"]
const IDS := ["CALIBRATION","DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func close_scene(s: AstraGameSession) -> void:
    var guard := 0
    while not s.voyage.get("scene",{}).is_empty() and guard < 40:
        guard += 1
        var scene: Dictionary = s.voyage["scene"]
        if int(s.voyage["line"]) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
            check(s.voyage_choose(0),"scene choice applied")
        else:
            s.voyage_next()
    check(guard < 40,"scene chain terminates")

func inspect_goal(s: AstraGameSession) -> bool:
    var fact := str(AstraVoyageContent.chapter(s.case_id).get("fact",""))
    for room_id in s.voyage_rooms():
        if str(s.voyage.get("room","")) != str(room_id):
            s.voyage_move(str(room_id),false)
            close_scene(s)
        for point in s.voyage_points():
            if str(point[4]) != fact:
                continue
            if s.voyage_inspect(str(point[0])):
                close_scene(s)
                return true
    return false

func _initialize() -> void:
    test_first_contact()
    test_story_contract()
    test_player_experienced_recap()
    test_narrative_continuity()
    if failures.is_empty():
        print("ASTRA STORY CONSISTENCY TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures:
        printerr("FAIL · " + failure)
    quit(1)

func test_first_contact() -> void:
    var s := AstraGameSession.new()
    s.setup("CALIBRATION",4242)
    s.begin_voyage()

    check(s.roster == ["mira","rho","dax","noa"],"CALIBRATION: exactly four initially awake")
    check(s.voyage_rooms() == ["medbay"],"CALIBRATION: first contact stays in medbay")
    check(not s.voyage_inspect("pod"),"CALIBRATION: evidence cannot be collected through the opening scene")
    close_scene(s)

    var points := s.voyage_points()
    var required := 0
    var optional := 0
    for point in points:
        if str(point[4]) == "power":
            required += 1
        if str(point[4]) == "vitals":
            optional += 1
    check(required == 1,"CALIBRATION: exactly one required investigation")
    check(optional == 1,"CALIBRATION: optional status check is separate")

    check(s.voyage_inspect("status"),"CALIBRATION: optional status can be checked directly")
    close_scene(s)
    check(not bool(s.voyage.get("goal_done",false)),"CALIBRATION: optional check does not solve required investigation")

    check(s.voyage_inspect("pod"),"CALIBRATION: required panel is a direct player action")
    close_scene(s)
    check(bool(s.voyage.get("goal_done",false)),"CALIBRATION: direct panel establishes the required fact")
    check(str(s.flags.get("contact_058",{}).get("step","")) == "ready","CALIBRATION: fact discussion and one review branch complete")
    check(s.voyage_can_finish(),"CALIBRATION: finish unlocks only after direct fact + review")
    check(s.finish_voyage(),"CALIBRATION: finishes")
    check(s.phase == "RESULT" and s.outcome == "CONTINUE","CALIBRATION: no surprise meeting/vote/night judgement")

func test_story_contract() -> void:
    var resolved_lines: Array[String] = []
    var payoff_types: Dictionary = {}
    for case_id in IDS:
        var chapter := AstraVoyageContent.chapter(case_id)
        for key in ["situation","goal","discovery","resolved","open_question","outro","next_hook","fact"]:
            check(str(chapter.get(key,"")).strip_edges() != "","%s: story framing has %s" % [case_id,key])
        var resolved := str(chapter.get("resolved",""))
        check(resolved not in resolved_lines,"%s: local answer is chapter-specific" % case_id)
        resolved_lines.append(resolved)
        check(resolved != str(chapter.get("open_question","")),"%s: answer and remaining question differ" % case_id)
        check(str(chapter.get("open_question","")).count("?") <= 1,"%s: one major residual question budget" % case_id)

        var reset := AstraVoyageContent.reset_framing(case_id)
        check(str(reset.get("title","")) != "" and str(reset.get("detail","")) != "","%s: RESET_FRAMING authored" % case_id)

        if case_id != "CALIBRATION":
            var beat := AstraVoyageContent.resolution_thread(case_id)
            check(not beat.is_empty(),"%s: local answer has an in-play resolution beat" % case_id)
            check(str(beat.get("requires_fact","")) == str(chapter.get("fact","")),"%s: resolution is gated by the chapter fact" % case_id)
            var awake := AstraVoyageContent.awake_roster(case_id)
            for who in beat.get("participants",[]):
                check(str(who) in awake,"%s: sleeping NPC '%s' cannot deliver resolution" % [case_id,who])
            payoff_types[str(beat.get("payoff_type",""))] = true
            check(not AstraVoyageContent.hook_thread(case_id).is_empty(),"%s: next hook is an actual in-play beat" % case_id)

        var discoverable := false
        for room in AstraVoyageContent.ROOMS.values():
            for point in room.get("points",[]):
                if str(point[4]) == str(chapter.get("fact","")):
                    discoverable = true
        check(discoverable,"%s: resolved fact starts from a discoverable world fact" % case_id)

    check(payoff_types.size() >= 3,"story rhythm: at least three payoff styles are used")

func test_player_experienced_recap() -> void:
    for i in range(IDS.size()):
        var case_id: String = IDS[i]
        var s := AstraGameSession.new()
        s.setup(case_id,6000+i)
        s.begin_voyage()
        close_scene(s)

        var before := s.story_recap()
        check(str(before.get("resolved","")) == "","%s: Result API cannot reveal unseen local answer" % case_id)

        check(inspect_goal(s),"%s: chapter goal fact is directly discoverable" % case_id)
        var after := s.story_recap()
        check(str(after.get("resolved","")) != "","%s: experienced local answer becomes recap-safe" % case_id)
        check(str(after.get("open_question","")) == str(AstraVoyageContent.chapter(case_id).get("open_question","")),"%s: authored open question enters live state" % case_id)
        if case_id != "CALIBRATION":
            check(bool(after.get("hook_seen",false)),"%s: next hook was experienced before recap" % case_id)
        var qid := case_id.to_lower() + "_question_after"
        check(s.voyage.get("questions",{}).has(qid),"%s: open_question becomes a Notebook question" % case_id)

func test_narrative_continuity() -> void:
    var memory := {}
    for i in range(IDS.size()):
        var case_id: String = IDS[i]
        var s := AstraGameSession.new()
        s.setup(case_id,7000+i)
        _check_case_data_clean(s.case_data,case_id)
        s.begin_voyage(memory)

        check(s.roster == AstraVoyageContent.awake_roster(case_id),"%s: roster matches authored join day" % case_id)
        check(s.case_data.get("roster",[]) == s.roster,"%s: case_data roster matches voyage roster" % case_id)

        close_scene(s)
        check(inspect_goal(s),"%s: local question has a playable answer path" % case_id)
        check(s.voyage_can_finish(),"%s: exploration finishes after answer + reaction + hook" % case_id)
        check(s.finish_voyage(),"%s: finish_voyage succeeds" % case_id)
        var framing := s.loop_reset_framing()
        check(str(framing.get("detail","")) != "","%s: loop transition has physical residue" % case_id)
        memory = s.voyage_memory()

func _check_case_data_clean(case_data: Dictionary, case_id: String) -> void:
    var blob := JSON.stringify(case_data)
    for name in RETIRED_NAMES:
        check(not blob.contains(name),"%s: case_data free of retired name '%s'" % [case_id,name])
    var challenge: Dictionary = case_data.get("challenge",{})
    if str(challenge.get("id","")) == "records":
        check(int(challenge.get("target",1)) <= case_data.get("ops",[]).size(),"%s: records challenge target within available ops" % case_id)
