extends SceneTree

func _fail(message: String) -> void:
    push_error("VERTICAL SLICE CI: " + message)
    quit(1)

func _init() -> void:
    var meta := AstraMetaProgress.new()
    if not meta.is_case_unlocked("DEAD_AIR"):
        _fail("Dead Air must be unlocked from a fresh archive")
        return
    if meta.is_case_unlocked("GLASS_GARDEN"):
        _fail("Glass Garden must start locked")
        return

    meta.case_counts["DEAD_AIR"] = 1
    if not meta.is_case_unlocked("GLASS_GARDEN"):
        _fail("Glass Garden did not unlock after Dead Air")
        return
    if meta.is_case_unlocked("ECHO_WARD"):
        _fail("Echo Ward unlocked too early")
        return

    meta.case_counts["GLASS_GARDEN"] = 1
    if not meta.is_case_unlocked("ECHO_WARD"):
        _fail("Echo Ward did not unlock after Glass Garden")
        return
    if not meta.campaign_complete() and meta.completed_campaign_cases() != 2:
        _fail("campaign completion counter is inconsistent")
        return

    for case_id in AstraMetaProgress.CAMPAIGN_CASES:
        var state := AstraHypothesisGameState.new()
        state.preferred_case_id = str(case_id)
        state.setup(101010)
        if state.case_id != str(case_id):
            _fail("preferred case selection failed for %s" % str(case_id))
            return
        if state.hidden_null_ids.size() != 2:
            _fail("%s did not create exactly two Null roles" % str(case_id))
            return
        if state.truth.evidence.size() != 8:
            _fail("%s does not expose the expected eight evidence records" % str(case_id))
            return
        if state.truth.incident.get("locations", []).size() != 4:
            _fail("%s does not expose four investigation locations" % str(case_id))
            return

    meta.case_counts["ECHO_WARD"] = 1
    if not meta.campaign_complete():
        _fail("campaign should be complete after all three incidents")
        return

    print("ASTRA 0.1.0 VERTICAL SLICE CI OK · campaign unlocks + 3 incident templates")
    quit(0)
