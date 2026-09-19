extends SceneTree
var failures: Array[String] = []
var checks := 0
const SAVE := "user://astra_redesign_test.cfg"
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("REDESIGN FAIL · " + label)
func _initialize() -> void:
    for case_id in AstraCaseCatalog.CAMPAIGN:
        for protocol in AstraGameSession.PROTOCOLS:
            for seed_value in [42,314,73131]:
                _case(str(case_id),str(protocol),seed_value)
    # 0.4.0 tightened the tutorial gate: one token search no longer unlocks the
    # next stage. The player has to spend the phase — every reachable clue, then
    # every statement — because the old single-search rule let people tap "next"
    # straight to a meeting they had nothing to say in.
    var tutorial := AstraGameSession.new()
    tutorial.setup("DEAD_AIR",8)
    tutorial.set_tutorial(true)
    tutorial.advance()
    check(not tutorial.can_advance(),"first investigation requires practice")
    tutorial.inspect_point("engine","records")
    check(not tutorial.can_advance(),"one search is no longer enough to skip the phase")
    var guard := 0
    while not tutorial.can_advance() and guard < 30:
        guard += 1
        var acted := false
        for room_id in tutorial.room_ids():
            for point in tutorial.investigation_points(room_id):
                if bool(point.get("available", false)) and not acted:
                    tutorial.inspect_point(room_id, str(point["id"]))
                    acted = true
        if not acted:
            break
    check(tutorial.can_advance(),"spending the investigation unlocks the next stage")
    tutorial.advance()
    check(not tutorial.can_advance() and tutorial.pending_event.is_empty(),"first interview stays focused")
    tutorial.ask("mira","ALIBI")
    check(not tutorial.can_advance(),"one statement is not the whole round")
    guard = 0
    while not tutorial.can_advance() and guard < 30:
        guard += 1
        var asked := false
        for npc_id in tutorial.living_ids():
            if not tutorial.known_claims.has(npc_id) and tutorial.talk_ap > 0 and not asked:
                tutorial.ask(npc_id, "ALIBI")
                asked = true
        if not asked:
            break
    check(tutorial.can_advance(),"hearing the room unlocks the meeting")
    for id in AstraCrewCatalog.ORDER:
        for mood in ["calm","warm","uneasy","tense"]:
            var path := AstraCrewCatalog.portrait_path(id,mood)
            check(ResourceLoader.exists(path),"portrait exists "+path)
            var texture: Texture2D = load(path)
            check(texture.get_image().detect_alpha() != Image.ALPHA_NONE,"real portrait alpha "+path)
    var public_clue := {"kind":"trace","category":"fiber","culprit":"mira","decoy":false}
    var disguise := public_clue.duplicate()
    disguise["culprit"]="rho"
    disguise["decoy"]=true
    check(AstraArt.clue(public_clue)==AstraArt.clue(disguise),"hidden role and decoy cannot change art")
    var icon := AstraArt.icon(AstraArt.clue(public_clue))
    check(icon.texture != null,"absolute item path resolves")
    icon.free()
    AstraGameSession.delete_snapshot(SAVE)
    if failures.is_empty():
        print("ASTRA REDESIGN TESTS OK · %d checks" % checks)
        quit()
    else:quit(1)
func _case(case_id: String, protocol: String, seed_value: int) -> void:
    var s := AstraGameSession.new()
    s.setup(case_id,seed_value,protocol)
    s.advance()
    var before := s.investigation_ap
    check(s.inspect_point("missing","missing").is_empty() and s.investigation_ap==before,"invalid hotspot has no cost")
    var selected: Dictionary = {}
    for room in s.room_ids():
        for point in s.investigation_points(room):
            if bool(point["available"]):
                selected=s.inspect_point(room,str(point["id"]))
                break
        if not selected.is_empty():break
    check(not selected.is_empty() and s.investigation_ap==before-1,"hotspot yields evidence once")
    var op: String = str(s.case_data["ops"][0]["id"])
    check(s.link_hypothesis(str(selected["id"]),"mira",op,"관련"),"manual hypothesis accepted")
    check(not s.link_hypothesis(str(selected["id"]),"mira",op,"관련"),"duplicate rejected")
    check(not s.link_hypothesis("missing","mira",op,"관련"),"unfound evidence rejected")
    s.save_snapshot(SAVE)
    var r := AstraGameSession.new()
    check(r.load_snapshot(SAVE) and r.hypotheses()==s.hypotheses(),"hypothesis survives save")
    check(r.rng.state==s.rng.state,"RNG restored")
    s.advance()
    r.advance()
    if not s.pending_event.is_empty():
        s.resolve_private_event(mini(1,s.pending_event.get("choices",[]).size()-1))
        r.resolve_private_event(mini(1,r.pending_event.get("choices",[]).size()-1))
    var old_ap := s.talk_ap
    var answer := s.ask("mira","PERSONAL")
    r.ask("mira","PERSONAL")
    check(bool(answer.get("ok",false)) and s.talk_ap==old_ap-1,"personal question costs one turn")
    var repeat := s.ask("mira","PERSONAL")
    check(not bool(repeat.get("ok",false)),"personal moment cannot be farmed")
    s.ask("mira","ALIBI")
    r.ask("mira","ALIBI")
    s.advance()
    r.advance()
    var actions := s.meeting_actions_left
    check(bool(s.present_hypothesis(0).get("ok",false)),"meeting accepts interpretation")
    r.present_hypothesis(0)
    check(s.meeting_actions_left==actions-1 and bool(s.clue_by_id(str(selected["id"]))["public"]),"hypothesis uses one action and shares facts")
    check(not bool(s.present_hypothesis(0).get("ok",false)),"same argument once per day")
    s.advance();r.advance()
    s.cast_vote("");r.cast_vote("")
    check(s.last_vote==r.last_vote,"save replay identical vote")
    s.advance();r.advance()
    if s.phase=="NIGHT":
        var kind := "rest" if seed_value==42 else "backup"
        var target: String = "self" if kind=="rest" else str(s.room_ids()[0])
        check(not bool(s.choose_night_action(kind,"missing").get("ok",false)),"invalid night target rejected")
        var result := s.choose_night_action(kind,target)
        var replay := r.choose_night_action(kind,target)
        check(bool(result.get("ok",false)) and result==replay,"night action replay deterministic")
        check(not bool(s.choose_night_action(kind,target).get("ok",false)),"night cannot be repeated")
        s.advance()
        if kind=="rest" and s.outcome=="":
            check(s.talk_ap_max()==AstraGameSession.BASE_TALK_AP+1+(1 if protocol=="EMPATH" else 0),"rest bonus next day")
