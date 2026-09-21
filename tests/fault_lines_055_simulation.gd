extends SceneTree

var failures: Array[String] = []
var checks := 0

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func _initialize() -> void:
    simulate_motives()
    simulate_incidents()
    if failures.is_empty():
        print("ASTRA 0.5.5 FAULT LINES SIMULATION OK · %d checks" % checks)
        quit(0)
    for failure in failures:
        push_error(failure)
    quit(1)

func simulate_motives() -> void:
    var roster := ["mira","rho","dax","noa","sena","vale","eli","lyra"]
    var total := 0
    var maximum := 0
    var suspicious_innocent := 0
    for loop_index in range(500):
        var nulls := [roster[loop_index % roster.size()]]
        var motives := AstraPersonalMotiveModel.assign(4000 + loop_index,loop_index,"ECHO_WARD",roster,roster,nulls)
        total += motives.size()
        maximum = maxi(maximum,motives.size())
        for who in motives:
            if who not in nulls:
                suspicious_innocent += 1
    var average := float(total) / 500.0
    check(maximum <= 3,"motive maximum")
    check(average >= 1.0 and average < 3.0,"motive average")
    check(suspicious_innocent > 300,"innocent suspicion exists")
    print("055 motive average=%.2f max=%d innocent_suspicion=%d" % [average,maximum,suspicious_innocent])

func simulate_incidents() -> void:
    var active := ["mira","rho","dax","noa","sena","vale","eli","lyra"]
    var coverage := {}
    for loop_index in range(1000):
        var incident := AstraIncidentModel.select(9000 + loop_index,loop_index,"LAST_LIGHT",[],active)
        var incident_id := str(incident.get("id",""))
        coverage[incident_id] = int(coverage.get(incident_id,0))+1
        var scene := AstraIncidentModel.scene(incident,loop_index,loop_index > 0)
        check(Array(scene.get("choices",[])).size() >= 2,"incident choice coverage")
        for choice in scene.get("choices",[]):
            var result := AstraIncidentModel.resolve(incident,choice,loop_index,4)
            check(str(result.get("outcome","")) in ["RESOLVED","PARTIAL","COSTLY","UNRESOLVED"],"incident resolve")
    check(coverage.size() >= 5,"incident variety")
    print("055 incident coverage=" + str(coverage))
