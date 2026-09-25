extends SceneTree

# 1.0 interlude tasks: four families (signal analysis, circuit diagnosis,
# evidence timeline, route planning). For each, over 16 seeds: the same seed
# gives the same layout, the answers are not a fixed index across seeds,
# the task can be solved (by keyboard input only) and left partially, a wrong
# step never dead-ends, completion fires once, and every interlude maps to a
# family with valid success/partial story results that never name a role.
#   godot --headless --path . --script res://tests/minigame_100_tests.gd

var checks := 0
var failures: Array = []

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        print("FAIL · " + label)

func _initialize() -> void:
    _run.call_deferred()

func _key(task: AstraShipTask, code: int) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    task.handle_key(event)

func _run() -> void:
    _signal()
    _circuit()
    _timeline()
    _route()
    _interlude_data()
    await process_frame
    if failures.is_empty():
        print("ASTRA MINIGAME 100 TESTS OK · %d checks" % checks)
        quit()
    else:
        print("ASTRA MINIGAME 100 TESTS FAILED · %d/%d" % [failures.size(), checks])
        quit(1)

func _outcome(task: AstraShipTask) -> Array:
    var out: Array = []
    task.finished.connect(func(r): out.append(r))
    return out

func _signal() -> void:
    var noise := {}
    var sources := {}
    for seed in range(16):
        var t := AstraSignalTrace.new()
        root.add_child(t)
        t.setup(seed, [], 0.05, "소렌")
        var again := AstraSignalTrace.new()
        root.add_child(again)
        again.setup(seed, [], 0.05, "소렌")
        check(t.noise_channel == again.noise_channel and t.source == again.source and t.freq_targets == again.freq_targets, "signal deterministic per seed")
        again.queue_free()
        noise[t.noise_channel] = true
        sources[t.source] = true
        var out := _outcome(t)
        # a wrong interference guess is answered, not fatal
        _key(t, KEY_1 + (t.noise_channel + 1) % 3)
        _key(t, KEY_SPACE)
        check(t.step == 0 and out.is_empty(), "signal: a wrong channel is explained, the task goes on")
        _key(t, KEY_1 + t.noise_channel)
        _key(t, KEY_SPACE)
        check(t.step == 1, "signal: the interference is found by keyboard")
        for c in range(3):
            if c == t.noise_channel:
                continue
            t._active = c
            var guard := 0
            while absf(float(t.freq[c]) - float(t.freq_targets[c])) > 0.02 and guard < 200:
                guard += 1
                _key(t, KEY_RIGHT if float(t.freq_targets[c]) > float(t.freq[c]) else KEY_LEFT)
            guard = 0
            while not t._matched(c) and guard < 200:
                guard += 1
                _key(t, KEY_UP)
            _key(t, KEY_SPACE)
            check(bool(t.locked[c]), "signal: channel aligned and locked with arrows")
        check(t.step == 2, "signal: both channels lead to the direction step")
        _key(t, KEY_1 + t.source)
        _key(t, KEY_SPACE)
        check(out == ["success"], "signal: the source read from the pulses succeeds")
        t.finish("partial")
        check(out.size() == 1, "signal: completion fires once")
        t.queue_free()
        var p := AstraSignalTrace.new()
        root.add_child(p)
        p.setup(seed, [], 0.05, "소렌")
        var pout := _outcome(p)
        _key(p, KEY_ESCAPE)
        p._input(_esc())
        check(pout == ["partial"], "signal: Esc leaves with a partial result")
        p.queue_free()
    check(noise.size() >= 2 and sources.size() >= 2, "signal: the answers differ between seeds")

# What a measurement would read if `module` were the failed one.
func _hypo(t: AstraPowerRoute, action: String, module: String) -> String:
    var fault_section := t._section_of(module)
    if action.begins_with("m:"):
        return "없음" if action.substr(2) == module else "정상"
    var section := int(action.substr(3))
    if section < fault_section:
        return "정상"
    return "약함" if Array(t.sections[fault_section]).size() > 1 else "없음"

func _esc() -> InputEventKey:
    var e := InputEventKey.new()
    e.keycode = KEY_ESCAPE
    e.pressed = true
    return e

func _circuit() -> void:
    var faults := {}
    var layouts := {}
    for seed in range(16):
        var t := AstraPowerRoute.new()
        root.add_child(t)
        t.setup(seed, "준")
        var again := AstraPowerRoute.new()
        root.add_child(again)
        again.setup(seed, "준")
        check(t.failed == again.failed and t.jumpers == again.jumpers and t._layout == again._layout, "circuit deterministic per seed")
        again.queue_free()
        faults[t.failed] = true
        layouts[t._layout] = true
        var out := _outcome(t)
        # A careful player: each measurement is the one that best splits the
        # modules still possible. Three always pin the fault (fairness).
        var candidates: Array = t._modules().slice(1)
        while t.probes_left > 0 and candidates.size() > 1:
            var best_action := ""
            var best_split := 99
            var actions: Array = []
            for i in range(t.sections.size()):
                if not t.readings.has(i):
                    actions.append("tp:%d" % i)
            for m in t._modules():
                if Array(t.sections[t._section_of(str(m))]).size() > 1 and not t.readings.has("m:" + str(m)):
                    actions.append("m:" + str(m))
            for action in actions:
                var groups := {}
                for c in candidates:
                    var r := _hypo(t, str(action), str(c))
                    groups[r] = int(groups.get(r, 0)) + 1
                var worst := 0
                for g in groups.values():
                    worst = maxi(worst, int(g))
                if worst < best_split:
                    best_split = worst
                    best_action = str(action)
            if best_action.begins_with("tp:"):
                _key(t, KEY_1 + int(best_action.substr(3)))
            else:
                _key(t, KEY_A + "ABCDEF".find(best_action.substr(2)))
            var actual := str(t.readings.get(int(best_action.substr(3)) if best_action.begins_with("tp:") else best_action, ""))
            candidates = candidates.filter(func(c): return _hypo(t, best_action, str(c)) == actual)
        check(not t.readings.is_empty(), "circuit: test points measured by keyboard")
        _key(t, KEY_SPACE)
        check(t.step == 1, "circuit: measuring leads to naming the fault")
        var fs := t._section_of(t.failed)
        check(candidates == [t.failed], "circuit: three measurements always pin the failed module (%s)" % str(candidates))
        _key(t, KEY_A + "ABCDEF".find(t.failed))
        _key(t, KEY_SPACE)
        check(t.step == 2, "circuit: the right module moves on to the bypass")
        var good := -1
        for i in range(t.jumpers.size()):
            var j: Dictionary = t.jumpers[i]
            if int(j["from"]) <= fs and fs < int(j["to"]) and int(j["cap"]) >= t.load_amps:
                good = i
        check(good >= 0, "circuit: a safe bypass always exists")
        _key(t, KEY_1 + good)
        _key(t, KEY_SPACE)
        check(out == ["success"], "circuit: fault + safe bypass succeeds")
        t.queue_free()
        var w := AstraPowerRoute.new()
        root.add_child(w)
        w.setup(seed, "준")
        var wout := _outcome(w)
        w.probe(0)
        w.primary_action()
        var wrong := ""
        for m in w._modules():
            if str(m) != w.failed:
                wrong = str(m)
        w.choose_module(wrong)
        w.primary_action()
        check(wout.is_empty() and w.step == 1, "circuit: a first wrong guess is explained")
        w.choose_module(wrong)
        w.primary_action()
        check(wout == ["partial"], "circuit: two wrong guesses end partially, never stuck")
        w.queue_free()
    check(faults.size() >= 3 and layouts.size() >= 2, "circuit: faults and layouts vary by seed")

func _timeline() -> void:
    var first_cards := {}
    for id in ["red_shift_samples", "second_watch_logs", "threshold_final"]:
        var data := AstraInterludes.data(id)
        var task_data: Dictionary = data.get("task", {})
        check(str(task_data.get("kind", "")) == "order" and task_data.has("gap_after") and Array(task_data.get("conclusions", [])).size() == 3, "timeline data: %s has a boundary and readings" % id)
        for seed in range(16):
            var t := AstraOrderTask.new()
            root.add_child(t)
            t.setup(seed, task_data, "노아")
            first_cards[str(t.items[0][0])] = true
            var out := _outcome(t)
            for rank in range(t.items.size()):
                for i in range(t.items.size()):
                    if int(t.items[i][1]) == rank:
                        _key(t, KEY_1 + i)
            _key(t, KEY_SPACE)
            check(t.step == 1, "timeline %s: ordered by keyboard" % id)
            _key(t, KEY_LEFT)
            for k in range(t.gap_after):
                _key(t, KEY_RIGHT)
            _key(t, KEY_SPACE)
            check(t.step == 2, "timeline %s: the boundary found" % id)
            var right := t._conclusions.find(t.insight)
            _key(t, KEY_1 + right)
            _key(t, KEY_SPACE)
            check(out == ["success"], "timeline %s: the reading that follows succeeds" % id)
            t.queue_free()
    check(first_cards.size() >= 3, "timeline: card order is shuffled per seed")

func _route() -> void:
    var layouts := {}
    var sealed := {}
    for seed in range(16):
        var data := AstraInterludes.data("blind_deck_door")
        var task_data: Dictionary = data.get("task", {})
        var t := AstraFieldTask.new()
        root.add_child(t)
        t.setup(seed, task_data)
        layouts[t._layout] = true
        sealed[t.sealed] = true
        var out := _outcome(t)
        # cheapest out and back through the open corridors (a planner's route)
        var path := _path(t, 0, t.target)
        var back := _path(t, t.target, 0)
        for n in path.slice(1) + back.slice(1):
            _key(t, KEY_1 + int(n))
        check(t.route_cost() <= t.budget, "route: the cheapest round trip fits the budget")
        _key(t, KEY_SPACE)
        check(out == ["success"], "route: a round trip within budget succeeds")
        t.queue_free()
        var over := AstraFieldTask.new()
        root.add_child(over)
        over.setup(seed, task_data)
        var oout := _outcome(over)
        check(not over.step_to(over.target) or over._edge_index(0, over.target) >= 0, "route: no jumping to an unconnected node")
        over.finish("partial")
        check(oout == ["partial"], "route: leaving is a partial result")
        over.queue_free()
    check(layouts.size() >= 2 and sealed.size() >= 2, "route: layouts and sealed corridors vary by seed")

func _path(t: AstraFieldTask, from: int, to: int) -> Array:
    var dist := {from: 0}
    var prev := {}
    var frontier: Array = [from]
    while not frontier.is_empty():
        frontier.sort_custom(func(x, y): return int(dist[x]) < int(dist[y]))
        var here: int = frontier.pop_front()
        for i in range(t.edges.size()):
            if i == t.sealed:
                continue
            var e: Array = t.edges[i]
            var other := int(e[1]) if int(e[0]) == here else (int(e[0]) if int(e[1]) == here else -1)
            if other < 0:
                continue
            var d := int(dist[here]) + int(t.costs[i])
            if not dist.has(other) or d < int(dist[other]):
                dist[other] = d
                prev[other] = here
                frontier.append(other)
    var path: Array = [to]
    while path[0] != from:
        path.push_front(prev[path[0]])
    return path

func _interlude_data() -> void:
    var families := {}
    for id in AstraInterludes.all_ids():
        var data := AstraInterludes.data(str(id))
        var kind := str(data.get("task", {}).get("kind", ""))
        if kind == "":
            continue
        check(kind in ["signal_trace", "power_route", "order", "safe_route"], "interlude %s uses a 1.0 task family (%s)" % [id, kind])
        families[kind] = int(families.get(kind, 0)) + 1
        var results: Dictionary = data.get("results", {})
        for key in ["success", "partial"]:
            check(results.has(key), "interlude %s has a %s result" % [id, key])
            for line in Dictionary(results.get(key, {})).get("lines", []):
                var text := str(line[1])
                check(not ("Null" in text and ("이다" in text or "였다" in text)), "interlude %s never names a role" % id)
    check(families.size() == 4, "four task families in use (%s)" % str(families))
