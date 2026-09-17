extends SceneTree

const CharacterPresentationScript = preload("res://scripts/character_presentation.gd")
const MeetingCinematicScript = preload("res://scripts/meeting_cinematic.gd")

class FakeNpc:
    extends RefCounted
    var display_name: String = "Mira"
    var accent: Color = Color("55d6ff")

func _init() -> void:
    var root_control := Control.new()
    root.add_child(root_control)

    var portrait := TextureRect.new()
    portrait.custom_minimum_size = Vector2(190, 240)
    root_control.add_child(portrait)

    var presentation = CharacterPresentationScript.new()
    portrait.add_child(presentation)
    presentation.attach(portrait)
    presentation.present("Mira", "Medical Officer", Color("55d6ff"), "calm", true)
    presentation.cue("ALIBI RESPONSE", Color("55d6ff"))
    presentation.pulse("tense")

    var meeting = MeetingCinematicScript.new()
    root_control.add_child(meeting)
    var npcs := {"mira": FakeNpc.new()}
    var events: Array[Dictionary] = [
        {"speaker":"mira", "kind":"claim", "text":"I was in medical during the blackout."},
        {"speaker":"mira", "kind":"challenge", "text":"That timeline does not match the access log."}
    ]
    meeting.play(events, npcs, 2)
    meeting.stop()

    print("ASTRA 0.1.1 PRESENTATION CI OK")
    quit(0)
