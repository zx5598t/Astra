class_name AstraFeedbackFX
extends CanvasLayer

# Screen-level feedback: phase banners, toasts, flashes and short procedural
# tones. No audio files are needed; every sound is synthesized on the fly.

var _flash: ColorRect
var _banner: PanelContainer
var _banner_title: Label
var _banner_subtitle: Label
var _banner_tween: Tween
var _toast_box: VBoxContainer
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0

func _ready() -> void:
    layer = 90
    _flash = ColorRect.new()
    _flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _flash.color = Color(1, 1, 1, 0)
    add_child(_flash)

    _banner = PanelContainer.new()
    _banner.anchor_left = 0.5
    _banner.anchor_right = 0.5
    _banner.anchor_top = 0.0
    _banner.anchor_bottom = 0.0
    _banner.offset_left = -330.0
    _banner.offset_right = 330.0
    _banner.offset_top = 150.0
    _banner.offset_bottom = 246.0
    _banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _banner.visible = false
    add_child(_banner)
    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 2)
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _banner.add_child(box)
    _banner_title = Label.new()
    _banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _banner_title.add_theme_font_size_override("font_size", 30)
    box.add_child(_banner_title)
    _banner_subtitle = Label.new()
    _banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _banner_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _banner_subtitle.add_theme_font_size_override("font_size", 15)
    _banner_subtitle.add_theme_color_override("font_color", Color("c5d5ea"))
    box.add_child(_banner_subtitle)

    _toast_box = VBoxContainer.new()
    _toast_box.anchor_left = 1.0
    _toast_box.anchor_right = 1.0
    _toast_box.anchor_top = 1.0
    _toast_box.anchor_bottom = 1.0
    _toast_box.offset_left = -420.0
    _toast_box.offset_right = -24.0
    _toast_box.offset_top = -260.0
    _toast_box.offset_bottom = -92.0
    _toast_box.alignment = BoxContainer.ALIGNMENT_END
    _toast_box.add_theme_constant_override("separation", 8)
    _toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_toast_box)

    for index in range(4):
        var player := AudioStreamPlayer.new()
        player.volume_db = -14.0
        add_child(player)
        _players.append(player)

func banner(title: String, subtitle: String, accent: Color, hold: float = 0.9) -> void:
    if _banner == null:
        return
    var box := AstraUI.style(Color(0.02, 0.045, 0.09, 0.96), Color(accent, 0.85), 12, 1, 18)
    box.shadow_color = Color(accent, 0.18)
    box.shadow_size = 18
    _banner.add_theme_stylebox_override("panel", box)
    _banner_title.text = title
    _banner_title.add_theme_color_override("font_color", accent)
    _banner_subtitle.text = subtitle
    _banner_subtitle.visible = subtitle != ""
    _banner.visible = true
    _banner.modulate.a = 0.0
    if _banner_tween != null and _banner_tween.is_valid():
        _banner_tween.kill()
    _banner_tween = create_tween()
    _banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.14)
    _banner_tween.tween_interval(hold)
    _banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.3)
    _banner_tween.tween_callback(func(): _banner.visible = false)

func toast(text: String, accent: Color, seconds: float = 3.2) -> void:
    if _toast_box == null:
        return
    var card := PanelContainer.new()
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_theme_stylebox_override("panel", AstraUI.style(Color(0.03, 0.06, 0.12, 0.95), Color(accent, 0.8), 8, 1, 12))
    var line := Label.new()
    line.text = text
    line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    line.add_theme_font_size_override("font_size", 14)
    line.add_theme_color_override("font_color", AstraUI.TEXT)
    card.add_child(line)
    _toast_box.add_child(card)
    while _toast_box.get_child_count() > 3:
        var old := _toast_box.get_child(0)
        _toast_box.remove_child(old)
        old.queue_free()
    card.modulate.a = 0.0
    var tween := card.create_tween()
    tween.tween_property(card, "modulate:a", 1.0, 0.15)
    tween.tween_interval(seconds)
    tween.tween_property(card, "modulate:a", 0.0, 0.35)
    tween.tween_callback(card.queue_free)

func flash(color: Color, peak_alpha: float = 0.16, duration: float = 0.3) -> void:
    if AstraUI.reduce_motion:
        return
    if _flash == null:
        return
    _flash.color = Color(color.r, color.g, color.b, 0.0)
    var tween := create_tween()
    tween.tween_property(_flash, "color:a", peak_alpha, duration * 0.25)
    tween.tween_property(_flash, "color:a", 0.0, duration * 0.75)

func shake(_target: Control, _intensity: float = 6.0) -> void:
    # 0.4.0: screen shake removed. It moved every panel the player was reading
    # and added nothing the banner and flash do not already say.
    pass

func play(key: String) -> void:
    match key:
        "select": _tone(540.0, 0.05, 0.10, 810.0)
        "click": _tone(760.0, 0.035, 0.08, 0.0)
        "talk": _tone(380.0, 0.06, 0.09, 570.0)
        "clue": _chord([660.0, 880.0], 0.16, 0.12)
        "phase": _tone(300.0, 0.14, 0.12, 450.0)
        "alert": _tone(170.0, 0.2, 0.18, 113.0)
        "slip": _chord([440.0, 554.0, 659.0], 0.22, 0.12)
        "secret": _chord([392.0, 523.0], 0.2, 0.1)
        "vote": _tone(140.0, 0.28, 0.2, 93.0)
        "night": _tone(110.0, 0.5, 0.12, 165.0)
        "kill": _tone(90.0, 0.45, 0.22, 60.0)
        "save": _chord([523.0, 659.0, 784.0], 0.3, 0.1)
        "win": _chord([523.0, 659.0, 784.0, 1046.0], 0.6, 0.1)
        "lose": _chord([220.0, 207.0, 196.0], 0.7, 0.12)
        _: _tone(700.0, 0.04, 0.08, 0.0)

func _player() -> AudioStreamPlayer:
    var player := _players[_next_player % _players.size()]
    _next_player += 1
    return player

func _tone(freq_a: float, duration: float, amplitude: float, freq_b: float = 0.0) -> void:
    _synth([freq_a], duration, amplitude, freq_b)

func _chord(freqs: Array, duration: float, amplitude: float) -> void:
    _synth(freqs, duration, amplitude, 0.0)

func _synth(freqs: Array, duration: float, amplitude: float, glide_to: float) -> void:
    if _players.is_empty() or DisplayServer.get_name() == "headless":
        return
    var player := _player()
    var generator := AudioStreamGenerator.new()
    generator.mix_rate = 22050.0
    generator.buffer_length = maxf(0.2, duration + 0.1)
    player.stream = generator
    player.play()
    var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
    if playback == null:
        return
    var frames := int(generator.mix_rate * duration)
    var phases: Array[float] = []
    for _f in freqs:
        phases.append(0.0)
    for i in range(frames):
        var progress := float(i) / maxf(1.0, float(frames))
        var attack := minf(1.0, float(i) / 220.0)
        var envelope := attack * pow(1.0 - progress, 1.8)
        var sample := 0.0
        for index in range(freqs.size()):
            var freq := float(freqs[index])
            if glide_to > 0.0 and index == 0:
                freq = lerpf(freq, glide_to, progress)
            phases[index] += TAU * freq / generator.mix_rate
            sample += sin(phases[index]) + sin(phases[index] * 2.0) * 0.12
        sample = sample / maxf(1.0, float(freqs.size())) * amplitude * envelope
        playback.push_frame(Vector2(sample, sample))
