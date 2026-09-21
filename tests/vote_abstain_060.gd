extends SceneTree
# 0.6.0 release-blocker regression: NPC ballots must be legal and explained.
var checks := 0
var failures: Array[String] = []
var total_votes := 0
var abstains := 0
var invalid_targets := 0
var self_votes := 0
var empty_reasons := 0
var abstain_reasons := {}
var null_abstains := 0
var innocent_abstains := 0

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_low_information_votes()
    test_ballot_invariants()
    test_null_behavior()
    test_explicit_ballot_records()
    print("NPC VOTE SIM · total %d · abstain %d · invalid %d · self %d · empty-reason %d" % [total_votes,abstains,invalid_targets,self_votes,empty_reasons])
    print("NPC VOTE ABSTAIN REASONS · " + JSON.stringify(abstain_reasons))
    print("NPC VOTE ABSTAIN TYPES · Null %d · innocent %d · unexplained %d" % [null_abstains,innocent_abstains,empty_reasons])
    if failures.is_empty():
        print("ASTRA 0.6.0 NPC VOTE REGRESSION OK · %d checks" % checks)
        quit(0)
    printerr("ASTRA 0.6.0 NPC VOTE REGRESSION FAILED · %d/%d" % [failures.size(),checks])
    quit(1)

func _record_session(s: AstraGameSession) -> void:
    var legal: Array = s.eligible_vote_targets()
    var intentions := s.vote_intentions()
    for voter in s.eligible_voters():
        total_votes += 1
        var target := str(intentions.get(voter,""))
        if target == "":
            abstains += 1
            if s.crew[str(voter)].is_null(): null_abstains += 1
            else: innocent_abstains += 1
            var trace := s._vote_decision_trace(str(voter),"")
            var why := str(trace.get("explanation",""))
            abstain_reasons[why] = int(abstain_reasons.get(why,0)) + 1
            if why.strip_edges() == "":
                empty_reasons += 1
            check(legal.is_empty(), "abstain only when no legal candidate exists: %s/%s" % [s.case_id,voter])
            check(why.strip_edges() != "", "abstain has human-readable reason")
            check(str(trace.get("strongest_reason","")) == "no_legal_vote_target", "abstain has explicit no-legal-target reason code")
        else:
            if target not in legal or not s.can_vote_for(str(voter),target):
                invalid_targets += 1
            if target == str(voter):
                self_votes += 1
            var trace := s._vote_decision_trace(str(voter),target)
            if str(trace.get("explanation","")).strip_edges() == "":
                empty_reasons += 1
            check(target in legal and s.can_vote_for(str(voter),target), "target is legal: %s -> %s" % [voter,target])
            check(target != str(voter), "self vote forbidden: %s" % voter)
            check(str(trace.get("explanation","")).strip_edges() != "", "non-abstain DecisionTrace is readable")
            check(not str(trace.get("explanation","")).contains("Null"), "player-facing reason does not expose hidden Null identity")

func test_low_information_votes() -> void:
    for seed in range(120):
        var s := AstraGameSession.new()
        s.setup("ECHO_WARD",10000+seed,"ANALYST","STANDARD",[])
        s.day = 1
        # No investigation is required here: this intentionally exercises the
        # early/low-public-evidence ballot path that used to threshold-abstain.
        _record_session(s)
    check(abstains == 0, "early low-information meetings have no fallback abstentions")

func test_ballot_invariants() -> void:
    for case_id in AstraCaseCatalog.CAMPAIGN:
        for seed in range(80):
            var s := AstraGameSession.new()
            s.setup(str(case_id),20000+seed*37,"ANALYST","STANDARD",[])
            _record_session(s)
    check(invalid_targets == 0, "simulation has zero invalid targets")
    check(self_votes == 0, "simulation has zero self votes")
    check(empty_reasons == 0, "simulation has zero empty reasons")

func test_null_behavior() -> void:
    var null_targets := {}
    var null_ballots := 0
    var null_abstains := 0
    for seed in range(300):
        var s := AstraGameSession.new()
        s.setup("LAST_LIGHT",30000+seed*53,"ANALYST","STANDARD",[])
        var intentions := s.vote_intentions()
        for null_id in s.truth.get("nulls",[]):
            null_ballots += 1
            var target := str(intentions.get(str(null_id),""))
            if target == "":
                null_abstains += 1
            else:
                null_targets[target] = int(null_targets.get(target,0)) + 1
                check(target != str(null_id), "Null never self-votes")
                check(s.can_vote_for(str(null_id),target), "Null target is legal")
    check(null_abstains == 0, "Null NPCs do not fallback-abstain when targets exist")
    check(null_targets.size() >= 4, "two-Null voting does not collapse to one fixed target (%d targets)" % null_targets.size())
    print("NULL VOTE SAMPLE · ballots %d · abstain %d · target identities %d" % [null_ballots,null_abstains,null_targets.size()])


func test_explicit_ballot_records() -> void:
    for seed in range(40):
        var s := AstraGameSession.new()
        s.setup("LAST_LIGHT",900000+seed*71,"ANALYST","STANDARD",[])
        s.phase = "VOTE"
        var result := s.cast_vote("")
        check(bool(result.get("ok",false)), "explicit abstain ballot can be recorded")
        for ballot in s.last_vote.get("ballots",[]):
            if str(ballot.get("voter","")) == "player":
                check(bool(ballot.get("abstain",false)), "player abstain is explicit")
                check(str(ballot.get("reason_code","")) == "player_abstain", "player abstain has reason code")
                continue
            var target := str(ballot.get("target",""))
            check(bool(ballot.get("abstain",false)) == (target == ""), "NPC ballot abstain flag matches target state")
            check(str(ballot.get("reason","")).strip_edges() != "", "NPC ballot stores readable reason")
            check(not Dictionary(ballot.get("decision_trace",{})).is_empty(), "NPC ballot stores DecisionTrace")
            if target == "":
                check(str(ballot.get("reason_code","")) == "no_legal_vote_target", "NPC abstain stores allowed reason code")
