extends SceneTree

# 1.0.1 evidence-fairness / role-tell audit.
# This inspects authored Day packets directly, independent of ACTIVE/PASSIVE
# progression, so a faster ACTIVE clear cannot make the route count look lower
# simply because it never reaches Day 2 or Day 3.

const CASES := ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD"]
const SEEDS := 100
const DAYS := 3

var failures: Array[String] = []
var checks := 0

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _origin(item: Dictionary) -> String:
    var type := str(item.get("type", ""))
    if type == "HEARSAY":
        return "witness:" + str(item.get("via", ""))
    if type in ["DIRECT_WITNESS", "NULL_DECEPTION", "BENIGN_EXPOSURE", "COVER_EXPOSURE"]:
        return "witness:" + str(item.get("owner", ""))
    if type in ["SYSTEM_RECORD", "ALIBI_SUPPORT"]:
        return "record:%s:%s" % [str(item.get("record_type", "")), str(item.get("owner", ""))]
    if type == "EXPERT_INFERENCE":
        return "expert:" + str(item.get("owner", ""))
    return "fact:" + str(item.get("id", ""))

func _route(signature: String, owners: Array, family: String) -> Dictionary:
    var unique := {}
    for owner in owners:
        if str(owner) != "":
            unique[str(owner)] = true
    return {"signature": signature, "owners": unique.keys(), "family": family}

func _packet_routes(packet: Dictionary) -> Array:
    var routes: Array = []
    var actor := str(packet.get("actor", ""))
    if actor == "":
        return routes
    var claims: Dictionary = packet.get("claims", {})
    var actor_claim: Dictionary = claims.get(actor, {})
    var actor_pos := str(actor_claim.get("position", ""))
    var fragments: Array = packet.get("fragments", [])

    # Route 1 shape: one independently owned observation or record names the
    # actor at the incident while the actor claims somewhere else. Getting the
    # actor's statement plus that source is two conversations at most.
    for raw in fragments:
        var item: Dictionary = raw
        var type := str(item.get("type", ""))
        var points: Array = item.get("points_to", [])
        if type in ["DIRECT_WITNESS", "SYSTEM_RECORD"] and points.size() == 1 and str(points[0]) == actor and str(item.get("room", "")) != actor_pos:
            routes.append(_route("direct:%s:%s" % [_origin(item), str(item.get("id", ""))], [actor, str(item.get("owner", ""))], "direct_claim"))
        if type == "EXPERT_INFERENCE" and str(item.get("refutes", "")) == actor:
            routes.append(_route("expert:%s" % _origin(item), [actor, str(item.get("owner", ""))], "expert_excuse"))

    # Route 2 shape: two independent partial sources overlap only on the actor.
    # The actor statement plus two source owners fits the Part-I three-contact
    # ceiling; if an owner is the actor it costs fewer contacts.
    for i in range(fragments.size()):
        var a: Dictionary = fragments[i]
        var ap: Array = a.get("points_to", [])
        if actor not in ap or ap.is_empty():
            continue
        for j in range(i + 1, fragments.size()):
            var b: Dictionary = fragments[j]
            var bp: Array = b.get("points_to", [])
            if actor not in bp or bp.is_empty():
                continue
            var oa := _origin(a)
            var ob := _origin(b)
            if oa == ob:
                continue
            if str(a.get("room", "")) != str(b.get("room", "")):
                continue
            var both: Array = []
            for id in ap:
                if id in bp:
                    both.append(str(id))
            if both.size() == 1 and str(both[0]) == actor:
                var pair := [oa, ob]
                pair.sort()
                routes.append(_route("intersection:%s" % str(pair), [actor, str(a.get("owner", "")), str(b.get("owner", ""))], "intersection"))

    # A borrowed alibi is another rational path: the Null says it was with an
    # innocent who honestly says otherwise.
    for other in claims:
        if str(other) == actor:
            continue
        var other_claim: Dictionary = claims[other]
        var actor_mates: Array = actor_claim.get("companions", [])
        var other_mates: Array = other_claim.get("companions", [])
        var same := actor_pos == str(other_claim.get("position", ""))
        if (str(other) in actor_mates or actor in other_mates) and not same:
            routes.append(_route("claim_conflict:%s" % str(other), [actor, str(other)], "claim_conflict"))

    # A false frame can be disproved by the framed person's independent record.
    for raw in fragments:
        var frame: Dictionary = raw
        if str(frame.get("type", "")) != "NULL_DECEPTION" or str(frame.get("owner", "")) != actor:
            continue
        var framed := str(frame.get("subject", ""))
        for raw2 in fragments:
            var support: Dictionary = raw2
            if str(support.get("type", "")) == "ALIBI_SUPPORT" and str(support.get("supports", "")) == framed and str(support.get("refutes", "")) == actor:
                routes.append(_route("frame_refute:%s:%s" % [_origin(frame), _origin(support)], [str(frame.get("owner", "")), str(support.get("owner", ""))], "frame_refute"))

    # De-duplicate semantically identical paths and keep only routes a careful
    # player can express within the 2-3 conversation budget.
    var unique := {}
    for route in routes:
        if Array(route.get("owners", [])).size() <= 3:
            unique[str(route.get("signature", ""))] = route
    return unique.values()

func _initialize() -> void:
    var total_multi := {}
    var total_zero := {}
    var null_frames := 0
    var innocent_mistakes := 0
    var benign_lies := 0
    for case_id in CASES:
        var zero := 0
        var one := 0
        var multi := 0
        var family_counts := {}
        for index in range(SEEDS):
            var seed_value := 17011 + index * 29
            var s := AstraGameSession.new()
            s.setup(case_id, seed_value)
            var active := s.active_participants()
            var nulls := s.living_null_ids()
            var all_routes := {}
            for day in range(1, DAYS + 1):
                var packet := AstraCaseGenerator.generate_day_packet(case_id, seed_value, day, active, nulls, "STANDARD", {})
                var errors := AstraCaseGenerator.validate_day_packet(packet, active, nulls)
                check(errors.is_empty(), "%s/%d/day%d packet fairness contract" % [case_id, seed_value, day])
                for route in _packet_routes(packet):
                    all_routes[str(route.get("signature", ""))] = route
                    var family := str(route.get("family", ""))
                    family_counts[family] = int(family_counts.get(family, 0)) + 1
                for raw in packet.get("fragments", []):
                    var item: Dictionary = raw
                    if str(item.get("type", "")) == "NULL_DECEPTION":
                        if str(item.get("owner", "")) in nulls and not bool(item.get("mistaken", false)):
                            null_frames += 1
                        elif bool(item.get("mistaken", false)) and str(item.get("owner", "")) not in nulls:
                            innocent_mistakes += 1
                var benign: Dictionary = packet.get("benign", {})
                if not benign.is_empty() and str(benign.get("npc", "")) not in nulls:
                    benign_lies += 1
            if all_routes.is_empty():
                zero += 1
            elif all_routes.size() == 1:
                one += 1
            else:
                multi += 1
        total_zero[case_id] = zero
        total_multi[case_id] = multi
        print("FAIRNESS %s · zero=%d one=%d multi=%d/100 · families=%s" % [case_id, zero, one, multi, str(family_counts)])
        check(zero <= 5, case_id + " almost every seed has at least one fair proof route")
        # This is deliberately not a 100% requirement: some seeds can make the
        # player choose among ambiguity rather than hand them two equivalent
        # proofs. A majority must still offer genuine route redundancy.
        check(multi >= 60, case_id + " most seeds expose two or more distinct proof routes")
    print("ROLE TELL AUDIT · null_false_sightings=%d innocent_false_sightings=%d benign_innocent_discrepancies=%d" % [null_frames, innocent_mistakes, benign_lies])
    check(null_frames > 0, "Nulls can create false sightings")
    check(innocent_mistakes > 0, "innocents can also create false sightings")
    check(benign_lies > 0, "innocents can have explainable discrepancies")
    if failures.is_empty():
        print("ASTRA FAIRNESS 101 TESTS OK · %d checks" % checks)
        quit(0)
        return
    print("ASTRA FAIRNESS 101 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)
