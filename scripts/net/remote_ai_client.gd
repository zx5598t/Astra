class_name AstraRemoteAIClient
extends Node

# Optional HTTP bridge to backend/app.py. The game never waits on it:
# rule-based lines are shown first and only replaced by validated responses.

signal action_received(request_id: String, action: Dictionary, success: bool, error_message: String)
signal health_checked(ok: bool, detail: String)

var endpoint: String = "http://127.0.0.1:8787/npc/action"
var busy: bool = false
var _http: HTTPRequest
var _health: HTTPRequest
var _pending_request_id: String = ""

func _ready() -> void:
    _http = HTTPRequest.new()
    _http.timeout = 12.0
    add_child(_http)
    _http.request_completed.connect(_on_request_completed)
    _health = HTTPRequest.new()
    _health.timeout = 3.0
    add_child(_health)
    _health.request_completed.connect(_on_health_completed)

func health_url() -> String:
    var base := endpoint
    var cut := base.find("/npc/")
    if cut >= 0:
        base = base.substr(0, cut)
    return base.trim_suffix("/") + "/health"

func check_health() -> void:
    if _health == null:
        health_checked.emit(false, "not_ready")
        return
    _health.cancel_request()
    var err := _health.request(health_url())
    if err != OK:
        health_checked.emit(false, "request_error_%d" % err)

func request_action(payload: Dictionary, request_id: String) -> bool:
    if busy or _http == null:
        return false
    busy = true
    _pending_request_id = request_id
    var headers := PackedStringArray(["Content-Type: application/json"])
    var err := _http.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        busy = false
        var failed_id := _pending_request_id
        _pending_request_id = ""
        action_received.emit(failed_id, {}, false, "request_error_%d" % err)
        return false
    return true

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    var request_id := _pending_request_id
    _pending_request_id = ""
    busy = false
    if result != HTTPRequest.RESULT_SUCCESS:
        action_received.emit(request_id, {}, false, "transport_%d" % result)
        return
    if response_code < 200 or response_code >= 300:
        action_received.emit(request_id, {}, false, "http_%d" % response_code)
        return
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if not (parsed is Dictionary):
        action_received.emit(request_id, {}, false, "invalid_json")
        return
    var action: Dictionary = parsed
    action_received.emit(request_id, action, bool(action.get("ok", false)), "")

func _on_health_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS:
        health_checked.emit(false, "서버에 연결할 수 없습니다 (transport %d)" % result)
        return
    if response_code != 200:
        health_checked.emit(false, "HTTP %d" % response_code)
        return
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if parsed is Dictionary and str(parsed.get("status", "")) == "ok":
        health_checked.emit(true, "연결됨 · 모델 %s" % str(parsed.get("model", "?")))
    else:
        health_checked.emit(false, "응답 형식이 올바르지 않습니다")
