extends SceneTree
# Evidence curve of generated Day Packets (tuning aid, not CI): per Stage and
# Day, how often the sighting / the log names the acting Null outright, and how
# many people the two traces together leave. Later Days drop two innocents a
# Day (one isolated, one lost at night) to approximate a real roster.
#   godot --headless --path . --script res://tests/probe_packets_080.gd -- --seeds=200
func _initialize() -> void:
    var seeds := 200
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--seeds="):
            seeds = int(a.substr(8))
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        var rows := {}
        for seed in range(1, seeds + 1):
            var seed_value := seed * 104729 + 7
            var truth := AstraCaseGenerator.generate(case_id, seed_value)
            var nulls: Array = truth.get("nulls", [])
            var active: Array = AstraCaseCatalog.roster(AstraCaseCatalog.resolve(case_id, seed_value)).duplicate()
            for d in range(1, 4):
                var innocents: Array = []
                for id in active:
                    if id not in nulls:
                        innocents.append(id)
                if innocents.size() < 2:
                    break
                var packet := AstraCaseGenerator.generate_day_packet(case_id, seed_value, d, active, nulls)
                var actor := str(packet.get("actor", ""))
                var row: Dictionary = rows.get(d, {"n": 0, "w_spec": 0, "e_spec": 0, "left1": 0, "left2": 0, "left3": 0, "frame": 0, "benign": 0, "hearsay": 0, "expert": 0})
                row["n"] = int(row["n"]) + 1
                var sets: Array = []
                var second := false
                var w_set: Array = []
                var e_set: Array = []
                for item in packet.get("fragments", []):
                    match str(item.get("type", "")):
                        "DIRECT_WITNESS":
                            if bool(item.get("specific", false)):
                                row["w_spec"] = int(row["w_spec"]) + 1
                            if not w_set.is_empty():
                                second = true
                            w_set = Array(item.get("points_to", []))
                            sets.append(w_set)
                        "SYSTEM_RECORD":
                            if bool(item.get("specific", false)):
                                row["e_spec"] = int(row["e_spec"]) + 1
                            e_set = Array(item.get("points_to", []))
                            sets.append(e_set)
                        "NULL_DECEPTION":
                            row["frame"] = int(row["frame"]) + 1
                        "HEARSAY":
                            row["hearsay"] = int(row["hearsay"]) + 1
                        "EXPERT_INFERENCE":
                            row["expert"] = int(row["expert"]) + 1
                if not Dictionary(packet.get("benign", {})).is_empty():
                    row["benign"] = int(row["benign"]) + 1
                var left: Array = Array(sets[0]).duplicate() if not sets.is_empty() else []
                for other in sets:
                    left = left.filter(func(x): return x in Array(other))
                if second:
                    row["second"] = int(row.get("second", 0)) + 1
                var key := "left%d" % clampi(left.size(), 1, 3)
                row[key] = int(row[key]) + 1
                rows[d] = row
                # Next Day: one innocent isolated, one lost at night.
                var drop: Array = innocents.duplicate()
                drop.shuffle()
                for i in range(mini(2, drop.size() - 1)):
                    active.erase(drop[i])
        var parts: Array = []
        for d in rows:
            var r: Dictionary = rows[d]
            var n := maxf(1.0, float(r["n"]))
            parts.append("D%d 2nd%d%% w_spec%d%% e_spec%d%% left1/2/3 %d/%d/%d%% frame%d%% benign%d%% hearsay%d%% expert%d%%" % [d,
                int(100.0 * r.get("second", 0) / n), int(100.0 * r["w_spec"] / n), int(100.0 * r["e_spec"] / n), int(100.0 * r["left1"] / n), int(100.0 * r["left2"] / n), int(100.0 * r["left3"] / n),
                int(100.0 * r["frame"] / n), int(100.0 * r["benign"] / n), int(100.0 * r["hearsay"] / n), int(100.0 * r["expert"] / n)])
        print("%-18s %s" % [case_id, " | ".join(PackedStringArray(parts))])
    quit()
