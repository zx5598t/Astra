extends RefCounted

static func close_scene(s: AstraGameSession) -> void:
    for i in range(60):
        var scene: Dictionary = s.voyage.get("scene",{})
        if scene.is_empty(): return
        if int(s.voyage.get("line",-1)) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty(): s.voyage_choose(0)
        else: s.voyage_next()

static func inspect_goal(s: AstraGameSession) -> bool:
    close_scene(s)
    if s.first_day_flow():
        var ok := s.voyage_inspect("pod")
        close_scene(s)
        return ok or s.voyage_can_finish()
    if bool(s.voyage.get("goal_done",false)): return true
    var goal := s.contact_objective()
    if not s.voyage_move(str(goal.get("room","medbay")),false): return false
    close_scene(s)
    var ok := s.voyage_inspect(str(goal.get("target","")))
    close_scene(s)
    return ok and bool(s.voyage.get("goal_done",false))
