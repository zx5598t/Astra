extends SceneTree

var checks := 0
var failures: Array[String] = []
const SAVE := "user://first_contact_058.session"

class BallotFixture extends AstraGameSession:
    var scripted: Dictionary = {}
    func vote_intentions() -> Dictionary:
        return scripted.duplicate()

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · "+label)

func close_scene(s: AstraGameSession, choice: int = 0) -> void:
    for i in range(40):
        var scene: Dictionary = s.voyage.get("scene",{})
        if scene.is_empty(): return
        if int(s.voyage.get("line",-1)) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
            s.voyage_choose(choice)
        else: s.voyage_next()
    check(false,"scene has bounded ending")

func round_trip(s: AstraGameSession, label: String) -> AstraGameSession:
    check(s.save_snapshot(SAVE),label+" save")
    var restored := AstraGameSession.new()
    check(restored.load_snapshot(SAVE),label+" load")
    check(s.truth == restored.truth,label+" generated truth unchanged")
    check(s.rng.state == restored.rng.state,label+" RNG unchanged")
    check(str(s.voyage.get("scene",{}).get("id","")) == str(restored.voyage.get("scene",{}).get("id","")),label+" scene preserved")
    return restored

func _initialize() -> void:
    test_first_day()
    test_schedule()
    test_votes()
    test_knowledge()
    test_legacy()
    AstraGameSession.delete_snapshot(SAVE)
    if failures.is_empty():
        print("ASTRA 0.5.8 FIRST CONTACT TESTS OK · %d checks" % checks)
        quit(0)
    else:
        printerr("ASTRA 0.5.8 FIRST CONTACT TESTS FAILED · %d/%d" % [failures.size(),checks])
        quit(1)

func test_first_day() -> void:
    for optional in [false,true]:
        for branch in [0,1]:
            var s := AstraGameSession.new()
            s.setup("CALIBRATION",8058)
            s.begin_voyage({"loops":19,"chapters":AstraCaseCatalog.CAMPAIGN,"evidence_ownership":{"secret":{"knows":["mira"]}}})
            check(s.roster == ["mira","rho","dax","noa"],"new game four even with meta unlocks")
            check(s.voyage_rooms() == ["medbay"],"one room required")
            check(not s.voyage_inspect("pod"),"no out-of-order inspection during introduction")
            s = round_trip(s,"introduction")
            check(s.skip_contact_intro(),"intro skip reaches same objective")
            check(not s.skip_contact_intro(),"skip idempotent")
            for i in range(12): s.voyage_move("medbay")
            check(not s.voyage["goal_done"] and s.voyage["facts"].is_empty(),"movement never gives evidence")
            s.voyage_ask_goal("mira")
            check(not s.voyage["goal_done"],"hint never gives evidence")
            check(not s.finish_voyage(),"continue cannot bypass actual action")
            if optional:
                check(s.voyage_inspect("status"),"optional first")
                close_scene(s)
                check(not s.voyage_inspect("status"),"optional cannot repeat")
            check(s.voyage_inspect("pod"),"one direct core inspection")
            check(not s.voyage_inspect("pod"),"double click cannot duplicate inspection")
            check(not s.voyage_can_finish(),"record needs review")
            s = round_trip(s,"record review")
            close_scene(s,branch)
            check(s.voyage_can_finish(),"one inspection plus branch completes first day")
            check(s.voyage["visits"] == ["medbay"],"no room touring")
            check(s.voyage["inspected"].size() == (2 if optional else 1),"1 required, at most 1 optional")
            check(s.flags["contact_058"]["learning"]["choice"] == "completed","learning only completed by action")
            check(str(s.flags["contact_058"]["review_choice"]) == ("check_source" if branch == 0 else "check_maintenance"),"choice has specific saved outcome")
            s = round_trip(s,"ready for next date")
            check(s.finish_voyage() and s.outcome == "CONTINUE","nonpunitive result")
            check(not s.finish_voyage(),"finish idempotent")
            check(s.isolations.is_empty() and s.casualties.is_empty(),"no surprise first-day failure")

func test_schedule() -> void:
    var cases := ["CALIBRATION","DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]
    var counts := [4,5,6,7,8,8,8]
    var arrivals := ["","sena","vale","eli","lyra","",""]
    for i in range(cases.size()):
        var s := AstraGameSession.new()
        s.setup(cases[i],902+i)
        s.begin_voyage()
        check(s.campaign_day() == i+1,"explicit calendar date")
        check(s.roster.size() == counts[i],"cumulative joined count")
        var truth_before := s.truth.duplicate(true)
        if arrivals[i] != "":
            check(s.voyage["scene"]["id"] == "arrival_"+arrivals[i],"new arrival leads current date")
            check(s.flags["contact_058"]["arrivals"].size() == 1,"one arrival event")
            s = round_trip(s,"arrival")
            s.begin_voyage()
            check(s.flags["contact_058"]["arrivals"].size() == 1,"reentry cannot apply join twice")
            close_scene(s)
            check(s.truth == truth_before,"arrival does not mutate generated case")
        for id in AstraCrewCatalog.ORDER:
            if id not in s.roster:
                check(not s.crew_state(id)["can_vote"] and not s.crew_state(id)["can_speak"],"unjoined cannot participate")
                check(not s.can_play_thread({"speaker":id,"lines":[[id,"안녕"]]}),"unjoined dialogue rejected")
        var original := s.roster.size()
        s.crew["mira"].status = AstraCrewMember.STATUS_ISOLATED
        check(s.roster.size() == original and s.active_participants().size() == original-1,"joined and active counts separate")

func test_votes() -> void:
    var s := BallotFixture.new()
    s.setup("ECHO_WARD",858)
    s.phase = "VOTE"
    for who in s.roster: s.scripted[who] = ""
    s.select("rho")
    s.set_mark("rho","null")
    check(s.ballot_choice()["state"] == "unselected","screen selection and marks do not select ballot")
    check(s.theories.is_empty() and not s.vote_cast,"memo has no automatic effects")
    check(not s.confirm_ballot().get("ok",false),"unselected cannot confirm")
    check(not s.select_ballot("target","invalid"),"invalid target distinct from abstention")
    check(s.select_ballot("abstain"),"explicit abstention")
    check(s.confirm_ballot().get("ok",false),"abstention can confirm")
    check(s.last_vote["result_reason"] == "all_abstained","all abstained distinct from tie")
    check(s.vote_counts()["abstained"] == s.roster.size()+1,"player abstention included")
    check(s.theories.is_empty(),"vote does not secretly submit marks")
    check(not s.confirm_ballot().get("ok",false),"repeat confirm blocked")
    check(AstraCrewCatalog.dot_path("") == "" and AstraCrewCatalog.cast_path("unknown") == "","invalid IDs never use Mira")
    s = BallotFixture.new()
    s.setup("ECHO_WARD",859)
    s.phase = "VOTE"
    for who in s.roster: s.scripted[who] = ""
    check(s.submit_theory(["rho"],60),"explicit report")
    s.set_mark("rho","clear")
    check(s.theories[0]["suspects"] == ["rho"],"report is immutable after memo change")
    check(not s.submit_theory(["mira"]),"report cannot duplicate")
    s.select_ballot("target","rho")
    var count := s.eligible_voters().size()+1
    s.confirm_ballot()
    check(s.last_vote["isolated"] == "rho" and s.last_vote["top"] == 1,"single highest one vote follows stated rule")
    check(s.vote_counts()["eligible"] == count,"snapshot includes just isolated voter")
    var restored := round_trip(s,"after vote")
    check(restored.vote_ballots() == s.vote_ballots(),"ballots survive resume without reroll")
    s = BallotFixture.new()
    s.setup("ECHO_WARD",860)
    s.phase = "VOTE"
    for who in s.roster: s.scripted[who] = ""
    s.scripted["noa"] = "mira"
    s.select_ballot("target","rho")
    s.confirm_ballot()
    check(s.last_vote["result_reason"] == "tie" and s.isolations.is_empty(),"tie has no isolation")
    for defect in ["bad_target","missing","extra"]:
        s = BallotFixture.new()
        s.setup("ECHO_WARD",861)
        s.phase = "VOTE"
        for who in s.roster: s.scripted[who] = ""
        if defect == "bad_target": s.scripted["noa"] = "not_a_person"
        elif defect == "missing": s.scripted.erase("noa")
        else: s.scripted["not_a_voter"] = "mira"
        s.select_ballot("abstain")
        check(not s.confirm_ballot().get("ok",false),"invalid or missing ballot blocks confirmation: "+defect)
        check(not s.vote_cast and s.isolations.is_empty(),"invalid data never silently votes or abstains")
        check(not s.flags.get("ballot_error_058",[]).is_empty(),"input error remains explicit and inspectable")

func test_knowledge() -> void:
    var s := AstraGameSession.new()
    s.setup("CALIBRATION",851)
    s.begin_voyage()
    check(not s.can_play_thread(AstraVoyageContent.first_thread("first_panel")),"unknown fact blocks thread")
    s.skip_contact_intro()
    s.voyage_inspect("pod")
    check(s.can_play_thread(AstraVoyageContent.first_thread("first_panel")),"joint panel grants participants knowledge")
    var invalid := AstraVoyageContent.first_thread("first_panel")
    invalid["beats"][1]["response_to"] = "other_thread:99"
    check(not s.can_play_thread(invalid),"wrong response target blocked")
    s.crew["rho"].status = AstraCrewMember.STATUS_ISOLATED
    check(not s.can_play_thread(AstraVoyageContent.first_thread("first_panel")),"absent participant blocks thread")

func test_legacy() -> void:
    var s := AstraGameSession.new()
    s.setup("ECHO_WARD",854)
    s.begin_voyage()
    s.flags.erase("contact_058")
    var before := s.roster.duplicate()
    var restored := round_trip(s,"legacy no optional keys")
    check(not restored.contact_flow() and restored.roster == before,"old save retains roster and old flow")
