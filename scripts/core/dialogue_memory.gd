class_name AstraDialogueMemory
extends RefCounted

# Keeps a short tail of "what was said recently" so the same sentence does not
# come back twice in five minutes.
#
# This is deliberately a bias, not a ban. Banning a line outright would make the
# rotation itself predictable ("she has used two of three, so the next one is
# the third"), and it would break determinism when a pool is small. Instead a
# recently used variant is weighted down and only wins when nothing else is
# available, which keeps the seed reproducible (§74) while removing the tape
# loop.

const WINDOW := 18

# `recent` is a plain Array of "npc:key:index" strings living in the save file.
static func remember(recent: Array, npc_id: String, key: String, index: int) -> void:
    recent.append("%s:%s:%d" % [npc_id, key, index])
    while recent.size() > WINDOW:
        recent.pop_front()

static func used_recently(recent: Array, npc_id: String, key: String, index: int) -> bool:
    return ("%s:%s:%d" % [npc_id, key, index]) in recent

# How many of the last WINDOW lines came from this exact variant. Used as the
# penalty weight, so a line said three lines ago is avoided harder than one said
# fifteen lines ago.
static func penalty(recent: Array, npc_id: String, key: String, index: int) -> float:
    var token := "%s:%s:%d" % [npc_id, key, index]
    var score := 0.0
    for position in range(recent.size()):
        if str(recent[position]) == token:
            # Later in the array means more recent, so it costs more.
            score += 1.0 + float(position) / float(maxi(1, recent.size()))
    return score

# Picks a variant index out of `size` options, avoiding what was used recently.
# `roll` is a deterministic value in [0, 1) from the session RNG, so the same
# seed still replays identically.
static func pick(recent: Array, npc_id: String, key: String, size: int, roll: float) -> int:
    if size <= 1:
        return 0
    var best: Array = []
    var best_penalty := INF
    for index in range(size):
        var cost := penalty(recent, npc_id, key, index)
        if cost < best_penalty - 0.0001:
            best_penalty = cost
            best = [index]
        elif absf(cost - best_penalty) <= 0.0001:
            best.append(index)
    var chosen := int(best[int(clampf(roll, 0.0, 0.999) * best.size())])
    remember(recent, npc_id, key, chosen)
    return chosen

# Share of lines in the window that are duplicates, for the repetition test.
static func repetition_rate(recent: Array) -> float:
    if recent.size() < 2:
        return 0.0
    var seen := {}
    var repeats := 0
    for token in recent:
        if seen.has(token):
            repeats += 1
        seen[token] = true
    return float(repeats) / float(recent.size())
