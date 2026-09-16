class_name AstraRemoteAIClient
extends Node

signal action_received(request_id: String, action: Dictionary, success: bool, error_message: String)

var endpoint: String = "http://127.0.0.1:8787/npc/action"
var busy: bool = false
var _http: HTTPRequest
var _pending_request_id: String = ""

func _ready() -> void:
    _http = HTTPRequest.new()
    add_child(_http)
    _http.timeout = 12.0
    _http.request_completed.connect(_on_request_completed)

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
