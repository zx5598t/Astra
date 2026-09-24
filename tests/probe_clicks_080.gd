extends SceneTree
# Required clicks per Stage for a thinking player (story beats + choices).
func _initialize() -> void:
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        var total := 0
        var story := 0
        var days := 0
        var games := 12
        for seed in range(1, games + 1):
            var s := AstraGameSession.new()
            var stage := AstraCaseCatalog.stage_index(case_id)
            s.setup(case_id, seed * 17 + 3, "GUARDIAN" if stage >= 5 else "NONE")
            var clicks := 0
            var guard := 0
            while s.phase != "RESULT" and guard < 80:
                guard += 1
                match s.phase:
                    "BRIEFING":
                        var g := 0
                        while not s.story_finished() and g < 200:
                            g += 1
                            clicks += 1
                            story += 1
                            var sc := s.story_scene()
                            if not Array(sc.get("choices", [])).is_empty() and s.story_line_index() >= Array(sc.get("lines", [])).size() - 1:
                                s.story_choose(0)
                            else:
                                s.story_next()
                        s.advance()
                    "INTERROGATION":
                        var leads := s.talk_leads()
                        for id in leads.keys() + s.living_ids():
                            if s.conversations_left() <= 0:
                                break
                            if s.conversation_open(str(id)):
                                continue
                            s.ask(str(id), "STATEMENT")
                            clicks += 1
                            var g2 := 0
                            while s.followups_left(str(id)) > 0 and g2 < 2:
                                g2 += 1
                                var o := s.question_options(str(id))
                                if o.is_empty():
                                    break
                                s.ask(str(id), str(o[0]["intent"]), str(o[0].get("ref", "")))
                                clicks += 1
                        clicks += 1
                        s.advance()
                    "MEETING":
                        var g3 := 0
                        var used := false
                        while not s.meeting_over() and g3 < 10:
                            g3 += 1
                            if not used:
                                var pick := AstraTestBots._smart_moment_pick(s)
                                if not pick.is_empty():
                                    s.intervene(str(pick["kind"]), str(pick["ref"]))
                                    clicks += 1
                                    used = true
                                    continue
                                clicks += 1
                            s.meeting_continue()
                        clicks += 1
                        s.advance()
                    "VOTE":
                        clicks += 2
                        AstraTestBots._vote(s, AstraTestBots._player_top(s))
                        if s.last_vote.has("tiebreak_choice") or str(s.last_vote.get("result_reason", "")) == "runoff":
                            clicks += 2
                        clicks += 1
                        s.advance()
                    "NIGHT":
                        clicks += 1
                        s.choose_night_action("protect", "player") if "player" in s.night_options().get("protect", []) else s.choose_night_action("skip", "")
                        s.advance()
            days += s.day
            total += clicks
        print("%-18s clicks/Stage %.0f (story beats %.0f) days %.1f" % [case_id, float(total) / games, float(story) / games, float(days) / games])
    quit()
