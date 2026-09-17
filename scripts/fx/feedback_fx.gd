class_name AstraFeedbackFX
extends CanvasLayer

var _flash: ColorRect
var _tone_player: AudioStreamPlayer
var _banner: PanelContainer
var _banner_title: Label
var _banner_subtitle: Label

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

    _banner = PanelContainer.new()
    _banner.anchor_left = 0.5
    _banner.anchor_right = 0.5
    _banner.offset_left = -310.0
    _banner.offset_right = 310.0
    _banner.offset_top = 170.0
    _banner.offset_bottom = 265.0
    _banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _banner.visible = false
    add_child(_banner)

    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 2)
    _banner.add_child(box)

    _banner_title = Label.new()
    _banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _banner_title.add_theme_font_size_override("font_size", 27)
    box.add_child(_banner_title)

    _banner_subtitle = Label.new()
    _banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _banner_subtitle.add_theme_font_size_override("font_size", 13)
    _banner_subtitle.add_theme_color_override("font_color", Color("c5d5ea"))
    box.add_child(_banner_subtitle)

func play(key: String) -> void:
    match key:
        "evidence": _play_tone(660.0, 0.11, 0.20, 440.0)
        "alert": _play_tone(170.0, 0.16, 0.22, 110.0)
        "select": _play_tone(520.0, 0.045, 0.12, 780.0)
        "talk": _play_tone(360.0, 0.055, 0.10, 540.0)
        "phase": _play_tone(300.0, 0.11, 0.14, 450.0)
        "unlock": _play_tone(740.0, 0.18, 0.16, 980.0)
        "complete": _play_tone(440.0, 0.22, 0.18, 660.0)
        _: _play_tone(820.0, 0.05, 0.16, 1200.0)

func play_case_sting(case_id: String) -> void:
    match case_id:
        "GLASS_GARDEN": _play_tone(260.0, 0.19, 0.13, 390.0)
        "ECHO_WARD": _play_tone(210.0, 0.21, 0.14, 315.0)
        _: _play_tone(180.0, 0.20, 0.13, 270.0)

func _play_tone(freq_a: float, duration: float, amplitude: float, freq_b: float = 0.0) -> void:
    if _tone_player == null:
        return
    var generator := AudioStreamGenerator.new()
    generator.mix_rate = 22050.0
    generator.buffer_length = 0.30
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

func phase_banner(title: String, subtitle: String, accent: Color) -> void:
    if _banner == null:
        return
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.055, 0.10, 0.96)
    style.border_color = Color(accent.r, accent.g, accent.b, 0.82)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.content_margin_left = 20
    style.content_margin_right = 20
    style.content_margin_top = 11
    style.content_margin_bottom = 11
    _banner.add_theme_stylebox_override("panel", style)
    _banner_title.text = title
    _banner_title.add_theme_color_override("font_color", accent)
    _banner_subtitle.text = subtitle
    _banner.visible = true
    _banner.modulate.a = 0.0
    _banner.position.y = -10.0
    var tween := _banner.create_tween()
    tween.set_parallel(true)
    tween.tween_property(_banner, "modulate:a", 1.0, 0.10)
    tween.tween_property(_banner, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.set_parallel(false)
    tween.tween_interval(0.72)
    tween.tween_property(_banner, "modulate:a", 0.0, 0.22)
    tween.tween_callback(func(): _banner.visible = false)

func shake(target: Control, intensity: float = 6.0) -> void:
    if target == null:
        return
    var origin := target.position
    var tween := create_tween()
    tween.tween_property(target, "position", origin + Vector2(intensity, 0), 0.035)
    tween.tween_property(target, "position", origin + Vector2(-intensity, 2), 0.035)
    tween.tween_property(target, "position", origin + Vector2(intensity * 0.55, -2), 0.035)
    tween.tween_property(target, "position", origin, 0.05)
