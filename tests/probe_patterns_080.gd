extends SceneTree
# §61–§62: can a player learn a formula instead of reading people?
# Over many Day 1s: how often the Null is (a) the first person publicly
# accused, (b) someone who claimed to be alone, (c) the person with a harmless
# lie; how the Null identity spreads over the crew; how often the same vote
# line and the same opening statement repeat.
func _initialize() -> void:
    var n := 0
    var first_accused_null := 0
    var accused_days := 0
    var alone_null := 0
    var alone_total := 0
    var benign_total := 0
    var null_counts := {}
    var vote_lines := {}
    var vote_total := 0
    var opens := {}
    var open_total := 0
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        for seed in range(1, 41):
            var s := AstraGameSession.new()
            s.setup(case_id, seed * 29 + 11)
            for id in s.living_null_ids():
                null_counts[id] = int(null_counts.get(id, 0)) + 1
            AstraTestBots._finish_morning(s)
            s.advance()
            for id in s.living_ids():
                if s.conversations_left() <= 0:
                    break
                var r := s.ask(str(id), "STATEMENT")
                for line in r.get("lines", []):
                    if str(line.get("speaker", "")) == str(id) and str(line.get("intent", "")) == "STATEMENT":
                        opens[str(line.get("text", ""))] = int(opens.get(str(line.get("text", "")), 0)) + 1
                        open_total += 1
            s.advance()
            s._finish_meeting()
            n += 1
            for entry in s.stage_state().get("public_accusations", []):
                if str(entry.get("speaker", "")) != "player":
                    accused_days += 1
                    if str(entry.get("target", "")) in s.living_null_ids():
                        first_accused_null += 1
                    break
            for id in s.living_ids():
                var claim := s.current_claim(str(id))
                if Array(claim.get("companions", [])).is_empty():
                    alone_total += 1
                    if str(id) in s.living_null_ids():
                        alone_null += 1
            if not Dictionary(s.current_packet().get("benign", {})).is_empty():
                benign_total += 1
            s.advance()
            s.cast_vote(str(s.eligible_vote_targets()[0]))
            for b in s.vote_ballots():
                var line := str(b.get("line", ""))
                if line != "":
                    vote_lines[line] = int(vote_lines.get(line, 0)) + 1
                    vote_total += 1
    print("Day-1 samples %d" % n)
    print("first NPC accusation hits a Null: %d%% of %d" % [100 * first_accused_null / maxi(1, accused_days), accused_days])
    print("claimed alone and is a Null: %d%% of %d alone claims" % [100 * alone_null / maxi(1, alone_total), alone_total])
    print("Days with a harmless liar: %d%%" % [100 * benign_total / maxi(1, n)])
    print("Null identity spread: %s" % str(null_counts))
    var top_vote := 0
    for k in vote_lines:
        top_vote = maxi(top_vote, int(vote_lines[k]))
    var top_open := 0
    for k in opens:
        top_open = maxi(top_open, int(opens[k]))
    print("distinct vote lines %d of %d ballots · most repeated %d" % [vote_lines.size(), vote_total, top_vote])
    print("distinct opening statements %d of %d · most repeated %d" % [opens.size(), open_total, top_open])
    var ranked: Array = opens.keys()
    ranked.sort_custom(func(a, b): return int(opens[a]) > int(opens[b]))
    for i in range(mini(6, ranked.size())):
        print("  %3d × %s" % [int(opens[ranked[i]]), str(ranked[i])])
    quit()
