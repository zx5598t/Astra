class_name AstraFeedbackFX
extends CanvasLayer

var _flash: ColorRect
var _tone_player: AudioStreamPlayer

func _ready() -> void:
    layer = 90
    _flash = ColorRect.new()
    _flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _flash.color = Color(1, 1, 1, 0)
    add_child(_flash)
    _tone_player = AudioStreamPlayer.new()
    _tone_player.volume_db = -13.0
    add_child(_tone_player)

func play(key: String) -> void:
    match key:
        "evidence": _play_tone(660.0, 0.11, 0.20, 440.0)
        "alert": _play_tone(170.0, 0.16, 0.22, 110.0)
        _: _play_tone(820.0, 0.05, 0.16, 1200.0)

func _play_tone(freq_a: float, duration: float, amplitude: float, freq_b: float = 0.0) -> void:
    if _tone_player == null:
        return
    var generator := AudioStreamGenerator.new()
    generator.mix_rate = 22050.0
    generator.buffer_length = 0.25
    _tone_player.stream = generator
    _tone_player.play()
    var playback := _tone_player.get_stream_playback() as AudioStreamGeneratorPlayback
    if playback == null:
        return
    var frames := int(generator.mix_rate * duration)
    for i in range(frames):
        var t := float(i) / generator.mix_rate
        var envelope := pow(1.0 - float(i) / maxf(1.0, float(frames)), 1.6)
        var sample := sin(TAU * freq_a * t)
        if freq_b > 0.0:
            sample += sin(TAU * freq_b * t) * 0.28
        sample *= amplitude * envelope
        playback.push_frame(Vector2(sample, sample))

func flash(color: Color, peak_alpha: float = 0.18) -> void:
    if _flash == null:
        return
    _flash.color = Color(color.r, color.g, color.b, 0.0)
    var tween := create_tween()
    tween.tween_property(_flash, "color:a", peak_alpha, 0.06)
    tween.tween_property(_flash, "color:a", 0.0, 0.24)

func shake(target: Control, intensity: float = 6.0) -> void:
    if target == null:
        return
    var origin := target.position
    var tween := create_tween()
    tween.tween_property(target, "position", origin + Vector2(intensity, 0), 0.035)
    tween.tween_property(target, "position", origin + Vector2(-intensity, 2), 0.035)
    tween.tween_property(target, "position", origin + Vector2(intensity * 0.55, -2), 0.035)
    tween.tween_property(target, "position", origin, 0.05)
