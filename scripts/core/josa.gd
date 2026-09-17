class_name AstraJosa
extends RefCounted

# Korean particle helper. Picks 은/는, 이/가, 을/를 ... from the final consonant
# of the word, so lines never fall back to the awkward "은(는)" form.

# Latin-script names as they are read aloud in Korean.
# true = the reading ends with a final consonant (받침).
const LATIN_FINAL := {
    "Mira": false, "Rho": false, "Eli": false, "Sena": false, "Vale": true,
    "Noa": false, "Lyra": false, "Dax": false, "Ives": false, "Orin": true,
    "Sael": true, "Null": true, "ASTRA": false, "Observer": false
}
# Readings that end in ㄹ (so 으로 becomes 로).
const LATIN_RIEUL := {"Vale": true, "Sael": true, "Null": true}

static func _last_char(word: String) -> String:
    var clean := word.strip_edges()
    while clean.length() > 0:
        var ch := clean.substr(clean.length() - 1, 1)
        if ch in [")", "]", "'", "\"", "’", "”", "…", ".", " ", "·"]:
            clean = clean.substr(0, clean.length() - 1)
            continue
        return ch
    return ""

static func _last_token(word: String) -> String:
    var clean := word.strip_edges()
    for separator in [" ", ",", "·", "("]:
        var at := clean.rfind(separator)
        if at >= 0:
            clean = clean.substr(at + 1)
    return clean.strip_edges().trim_suffix(")").trim_suffix(".")

static func has_final(word: String) -> bool:
    var key := _last_token(word)
    if LATIN_FINAL.has(key):
        return bool(LATIN_FINAL[key])
    var ch := _last_char(word)
    if ch == "":
        return false
    var code := ch.unicode_at(0)
    if code >= 0xAC00 and code <= 0xD7A3:
        return (code - 0xAC00) % 28 != 0
    if ch >= "0" and ch <= "9":
        return ch in ["0", "1", "3", "6", "7", "8"]
    return not (ch.to_lower() in ["a", "e", "i", "o", "u", "y"])

static func _is_rieul(word: String) -> bool:
    var key := _last_token(word)
    if LATIN_RIEUL.has(key):
        return true
    if LATIN_FINAL.has(key):
        return false
    var ch := _last_char(word)
    if ch == "":
        return false
    var code := ch.unicode_at(0)
    if code >= 0xAC00 and code <= 0xD7A3:
        return (code - 0xAC00) % 28 == 8
    return ch in ["1", "7", "8"]

static func eun(word: String) -> String:
    return word + ("은" if has_final(word) else "는")

static func i(word: String) -> String:
    return word + ("이" if has_final(word) else "가")

static func eul(word: String) -> String:
    return word + ("을" if has_final(word) else "를")

static func wa(word: String) -> String:
    return word + ("과" if has_final(word) else "와")

static func ro(word: String) -> String:
    if has_final(word) and not _is_rieul(word):
        return word + "으로"
    return word + "로"

static func a(word: String) -> String:
    return word + ("아" if has_final(word) else "야")

static func ira(word: String) -> String:
    return word + ("이라" if has_final(word) else "라")

static func ida(word: String) -> String:
    return word + ("이다" if has_final(word) else "다")

static func iya(word: String) -> String:
    return word + ("이야" if has_final(word) else "야")

static func ieyo(word: String) -> String:
    return word + ("이에요" if has_final(word) else "예요")

static func attach(word: String, particle: String) -> String:
    match particle:
        "eun": return eun(word)
        "i": return i(word)
        "eul": return eul(word)
        "wa": return wa(word)
        "ro": return ro(word)
        "a": return a(word)
        "ira": return ira(word)
        "ida": return ida(word)
        "iya": return iya(word)
        "ieyo": return ieyo(word)
    return word

# Replaces {key} and {key|particle} tokens, e.g. "{target|eul} 봤어요".
static func fill(template: String, params: Dictionary) -> String:
    var out := ""
    var cursor := 0
    while cursor < template.length():
        var open := template.find("{", cursor)
        if open < 0:
            out += template.substr(cursor)
            break
        var close := template.find("}", open)
        if close < 0:
            out += template.substr(cursor)
            break
        out += template.substr(cursor, open - cursor)
        var token := template.substr(open + 1, close - open - 1)
        var key := token
        var particle := ""
        var bar := token.find("|")
        if bar >= 0:
            key = token.substr(0, bar)
            particle = token.substr(bar + 1)
        if params.has(key):
            out += attach(str(params[key]), particle)
        else:
            out += "{" + token + "}"
        cursor = close + 1
    return out

# "Mira", "Mira와 Noa", "Mira, Noa와 Dax"
static func join_names(names: Array) -> String:
    if names.is_empty():
        return ""
    if names.size() == 1:
        return str(names[0])
    var head: Array = []
    for index in range(names.size() - 1):
        head.append(str(names[index]))
    return wa(", ".join(PackedStringArray(head))) + " " + str(names[names.size() - 1])
