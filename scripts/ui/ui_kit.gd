class_name AstraUI
extends RefCounted

# Shared palette and widget factories. Every screen builds its controls here
# so spacing, colors and button states stay consistent.

const BG := Color("080d16")
const PANEL := Color("101b2a")
const PANEL_2 := Color("162333")
const PANEL_3 := Color("20334a")
const BORDER := Color("293d52")
const BORDER_HI := Color("527087")
const TEXT := Color("edf3f5")
const MUTED := Color("a3b5c6")
const DIM := Color("7e94aa")
const CYAN := Color("8fbee5")
const GREEN := Color("5ee3a0")
const RED := Color("ff6f7f")
const GOLD := Color("ffd36a")
const PINK := Color("ff9ed1")
const VIOLET := Color("b88cff")
const NIGHT := Color("8f9cff")

static var reading_scale: float = 1.0
static var reduce_motion: bool = false

# ---------------------------------------------------------------- type scale
#
# 0.3.1 passed a raw pixel size at roughly forty call sites, so "body text" was
# 13, 14, 15 or 16 depending on which screen you were on, and nothing looked
# deliberate. These are the only sizes 0.4.0 introduces.
#
# The floor matters. At 1366x768 — the minimum window, and the size this game
# actually ships at — Korean text below 16px is uncomfortable at arm's length on
# a laptop panel. 0.3.1 used 12px captions; 0.4.0 first moved the floor to 14 and
# playtesting said that was still too small, so the whole scale moved up a step.
const T_DISPLAY := 44   # case title on a title or result screen
const T_TITLE := 30     # screen heading
const T_HEAD := 23      # panel heading, speaker name
const T_BODY := 19      # dialogue and prose: the size most text should be
const T_UI := 17        # buttons and controls
const T_META := 16      # supporting detail; the smallest size allowed

const LINE_SPACING := 6

# A line of Korean prose stops being comfortable past roughly this width, so
# dialogue panels are capped rather than stretched to the whole window.
const MAX_LINE_PX := 760

static func font_size(size: int) -> int:
    # Small text follows the reading-size option; headings are already large
    # enough that scaling them only costs layout room.
    return int(round(size * reading_scale)) if size <= T_HEAD else size

const MARK_COLORS := {"null": RED, "clear": GREEN, "unsure": GOLD}
const MARK_TEXT := {"null": "N", "clear": "✓", "unsure": "?"}
const MARK_LABEL := {"null": "Null 의심", "clear": "신뢰", "unsure": "보류"}

static func style(bg: Color = PANEL, border: Color = BORDER, radius: int = 10, border_width: int = 1, margin: int = 14) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = bg
    box.border_color = border
    box.set_border_width_all(border_width)
    box.set_corner_radius_all(radius)
    box.content_margin_left = margin
    box.content_margin_right = margin
    box.content_margin_top = margin
    box.content_margin_bottom = margin
    box.anti_aliasing = true
    return box

static func panel(bg: Color = PANEL, border: Color = BORDER, radius: int = 10, margin: int = 14) -> PanelContainer:
    var container := PanelContainer.new()
    container.add_theme_stylebox_override("panel", style(bg, border, radius, 1, margin))
    return container

static func label(text: String, size: int = 16, color: Color = TEXT, wrap: bool = false) -> Label:
    var node := Label.new()
    node.text = text
    node.add_theme_font_size_override("font_size", font_size(size))
    node.add_theme_color_override("font_color", color)
    if wrap:
        node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return node

static func rich(size: int = 16, fit: bool = true) -> RichTextLabel:
    var node := RichTextLabel.new()
    node.bbcode_enabled = true
    node.fit_content = fit
    node.scroll_active = not fit
    node.selection_enabled = false
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    node.add_theme_font_size_override("normal_font_size", font_size(size))
    node.add_theme_font_size_override("bold_font_size", font_size(size))
    node.add_theme_font_size_override("italics_font_size", font_size(size))
    node.add_theme_color_override("default_color", TEXT)
    return node

static func button(text: String, accent: Color = CYAN, size: int = 16, min_height: int = 44, filled: bool = false) -> Button:
    var node := Button.new()
    node.text = text
    node.focus_mode = Control.FOCUS_ALL
    node.custom_minimum_size = Vector2(0, min_height)
    node.add_theme_font_size_override("font_size", size)
    node.add_theme_color_override("font_color", TEXT)
    node.add_theme_color_override("font_hover_color", Color.WHITE)
    node.add_theme_color_override("font_pressed_color", Color.WHITE)
    node.add_theme_color_override("font_disabled_color", DIM)
    var base_alpha := 0.34 if filled else 0.12
    var normal := style(Color(accent, base_alpha), Color(accent, 0.75), 8, 1, 10)
    normal.content_margin_top = 6
    normal.content_margin_bottom = 6
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color(accent, base_alpha + 0.16)
    hover.border_color = accent
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color(accent, base_alpha + 0.3)
    var disabled := normal.duplicate() as StyleBoxFlat
    disabled.bg_color = Color(PANEL_2, 0.7)
    disabled.border_color = Color(BORDER, 0.8)
    node.add_theme_stylebox_override("normal", normal)
    node.add_theme_stylebox_override("hover", hover)
    node.add_theme_stylebox_override("pressed", pressed)
    node.add_theme_stylebox_override("disabled", disabled)
    var focus := style(Color.TRANSPARENT, Color.WHITE, 8, 2, 0)
    node.add_theme_stylebox_override("focus", focus)
    node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    return node

static func chip(text: String, color: Color, size: int = 12) -> PanelContainer:
    var container := PanelContainer.new()
    var box := style(Color(color, 0.14), Color(color, 0.6), 6, 1, 6)
    box.content_margin_top = 2
    box.content_margin_bottom = 2
    container.add_theme_stylebox_override("panel", box)
    container.add_child(label(text, size, color))
    return container

static func meter(value: float, color: Color, height: int = 6) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.min_value = 0.0
    bar.max_value = 1.0
    bar.value = clampf(value, 0.0, 1.0)
    bar.show_percentage = false
    bar.custom_minimum_size = Vector2(0, height)
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var back := StyleBoxFlat.new()
    back.bg_color = Color(PANEL_3, 0.9)
    back.set_corner_radius_all(3)
    var fill := StyleBoxFlat.new()
    fill.bg_color = color
    fill.set_corner_radius_all(3)
    bar.add_theme_stylebox_override("background", back)
    bar.add_theme_stylebox_override("fill", fill)
    return bar

static func hbox(separation: int = 8) -> HBoxContainer:
    var node := HBoxContainer.new()
    node.add_theme_constant_override("separation", separation)
    return node

static func vbox(separation: int = 8) -> VBoxContainer:
    var node := VBoxContainer.new()
    node.add_theme_constant_override("separation", separation)
    return node

static func spacer(horizontal: bool = true) -> Control:
    var node := Control.new()
    if horizontal:
        node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    else:
        node.size_flags_vertical = Control.SIZE_EXPAND_FILL
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node

static func scroll(content: Control, horizontal: bool = false) -> ScrollContainer:
    var node := ScrollContainer.new()
    node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if horizontal else ScrollContainer.SCROLL_MODE_DISABLED
    node.size_flags_vertical = Control.SIZE_EXPAND_FILL
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    node.add_child(content)
    return node

static func margin(child: Control, left: int, top: int, right: int, bottom: int) -> MarginContainer:
    var node := MarginContainer.new()
    node.add_theme_constant_override("margin_left", left)
    node.add_theme_constant_override("margin_top", top)
    node.add_theme_constant_override("margin_right", right)
    node.add_theme_constant_override("margin_bottom", bottom)
    node.add_child(child)
    return node

static func clear(node: Node) -> void:
    if node == null:
        return
    for child in node.get_children():
        node.remove_child(child)
        child.queue_free()

static func section(title: String, color: Color = CYAN) -> Label:
    var node := label(title, 13, color)
    node.uppercase = false
    return node

static func texture(path: String) -> Texture2D:
    if path != "" and ResourceLoader.exists(path):
        return load(path)
    return null

static func thumb(path: String, size: Vector2) -> TextureRect:
    var rect := TextureRect.new()
    rect.texture = texture(path)
    rect.custom_minimum_size = size
    rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return rect

static func fade_in(node: CanvasItem, duration: float = 0.18, delay: float = 0.0) -> void:
    if node == null or not node.is_inside_tree():
        return
    if reduce_motion:
        node.modulate.a = 1.0
        return
    node.modulate.a = 0.0
    var tween := node.create_tween()
    if delay > 0.0:
        tween.tween_interval(delay)
    tween.tween_property(node, "modulate:a", 1.0, duration)

static func hex(color: Color) -> String:
    return color.to_html(false)

static func escape(text: String) -> String:
    return text.replace("[", "[lb]")

static func pips(current: int, maximum: int, color: Color) -> String:
    var text := ""
    for index in range(maximum):
        text += "[color=#%s]●[/color]" % hex(color) if index < current else "[color=#%s]○[/color]" % hex(DIM)
    return text

# ---------------------------------------------------------------- 0.4.0 kit

# Prose that should be read, not scanned: wrapped, line-spaced and width-capped.
static func prose(text: String, size: int = T_BODY, color: Color = TEXT) -> Label:
    var node := label(text, size, color, true)
    node.add_theme_constant_override("line_spacing", LINE_SPACING)
    node.custom_minimum_size.x = 0
    return node

# A rich-text block with the same reading rules.
static func rich_prose(size: int = T_BODY) -> RichTextLabel:
    var node := rich(size, true)
    node.add_theme_constant_override("line_separation", LINE_SPACING)
    return node

# ---- information hierarchy -------------------------------------------------
#
# Three levels, and every screen assigns each piece of information to exactly
# one of them. PRIMARY is what you must know right now, SECONDARY helps you
# decide, DETAIL is opened on purpose. 0.3.1 drew all three at the same size in
# the same colour, which is why the screens read as dense rather than as busy.

static func primary(text: String, accent: Color = TEXT) -> Label:
    return label(text, T_TITLE, accent)

static func secondary(text: String, accent: Color = MUTED) -> Label:
    return label(text, T_META, accent)

# A labelled block: small dim caption over a normal-weight value.
static func field(caption: String, value: String, accent: Color = TEXT, value_size: int = T_HEAD) -> VBoxContainer:
    var box := vbox(1)
    box.add_child(label(caption, T_META, DIM))
    box.add_child(label(value, value_size, accent))
    return box

# The one action a screen exists for. Only ever one of these per screen.
static func primary_button(text: String, accent: Color = CYAN) -> Button:
    var node := button(text, accent, T_HEAD, 54, true)
    node.custom_minimum_size.x = 300
    return node

# Everything else.
static func secondary_button(text: String, accent: Color = MUTED) -> Button:
    return button(text, accent, T_UI, 42, false)

# ---- components ------------------------------------------------------------

# The persistent "what am I supposed to do" strip (§11). It is one line, it is
# always in the same place, and it never contains a rule explanation — that is
# what the help button beside it is for.
static func objective_strip(text: String, accent: Color = CYAN) -> PanelContainer:
    var card := panel(Color(accent, 0.09), Color(accent, 0.42), 8, 10)
    var row := hbox(10)
    card.add_child(row)
    row.add_child(label("지금 할 일", T_META, accent))
    var body := label(text, T_BODY, TEXT, true)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(body)
    return card

# The round [?] that opens help for the screen the player is on, not a manual.
static func help_button() -> Button:
    var node := button("?", CYAN, T_UI, 36, false)
    node.custom_minimum_size = Vector2(36, 36)
    node.tooltip_text = "이 화면에서 할 수 있는 일"
    return node

# First-appearance card: art, name, job, one line. Nothing else — a personality
# dossier on first sight is a wall of text about a stranger (§21).
static func intro_card(npc_id: String, display_name: String, job: String, line: String, accent: Color) -> PanelContainer:
    var card := panel(Color(0.03, 0.05, 0.09, 0.96), Color(accent, 0.55), 14, 0)
    var row := hbox(0)
    card.add_child(row)
    var art := thumb(AstraCrewCatalog.cast_path(npc_id, "calm", true), Vector2(240, 320))
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    row.add_child(art)
    var box := vbox(6)
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(margin(box, 22, 26, 22, 26))
    box.add_child(label(job, T_META, accent))
    box.add_child(label(display_name, T_DISPLAY, TEXT))
    box.add_child(spacer(false))
    var quote := prose("“" + line + "”", T_BODY, TEXT)
    box.add_child(quote)
    return card

# One speaker in the meeting. Portrait, name, tag, then the line — in that
# reading order, so the player knows who is talking before they read the words.
static func speaker_card(npc_id: String, display_name: String, tag: String, tag_color: Color, text: String, accent: Color, is_player: bool = false) -> PanelContainer:
    var card := panel(Color(accent, 0.12) if is_player else PANEL_2, Color(accent, 0.55 if is_player else 0.26), 10, 12)
    var row := hbox(12)
    card.add_child(row)
    if not is_player:
        var art := thumb(AstraCrewCatalog.dot_path(npc_id), Vector2(54, 54))
        art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        art.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        row.add_child(art)
    var box := vbox(4)
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(box)
    var head := hbox(8)
    box.add_child(head)
    head.add_child(label(display_name, T_HEAD, accent))
    if tag != "":
        head.add_child(chip(tag, tag_color, T_META - 2))
    var body := prose(text, T_BODY, TEXT)
    body.custom_minimum_size.x = 0
    box.add_child(body)
    return card

# Short toast-like notice used for unlocks: what opened, and what it means in
# the fiction. Both, or neither — a bare "UNLOCKED" teaches nothing (§35).
static func unlock_card(title: String, blurb: String, flavor: String) -> VBoxContainer:
    var box := vbox(10)
    box.add_child(label(title, T_TITLE, GOLD))
    box.add_child(prose(blurb, T_BODY, TEXT))
    if flavor != "":
        var line := prose(flavor, T_BODY, CYAN)
        line.add_theme_constant_override("line_spacing", LINE_SPACING)
        box.add_child(line)
    return box

# ---- who is this again? ----------------------------------------------------
#
# Eight strangers with unfamiliar names is the single biggest source of "wait,
# which one is that". Every place a crew member is named, 0.4.0 shows the same
# three things together: the sprite, the Korean name, and the job. Recognising a
# face is free; remembering a transliterated name is not.

static func crew_tag(npc_id: String, size: int = T_BODY, show_job: bool = true, dot_size: int = 30) -> HBoxContainer:
    var row := hbox(7)
    var dot := thumb(AstraCrewCatalog.dot_path(npc_id), Vector2(dot_size, dot_size))
    dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(dot)
    var name_label := label(AstraCrewCatalog.display_name(npc_id), size, AstraCrewCatalog.accent(npc_id))
    name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(name_label)
    if show_job:
        var job := label("(%s)" % str(AstraCrewCatalog.info(npc_id).get("job", "")), maxi(T_META, size - 3), DIM)
        job.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        row.add_child(job)
    return row

# Just the sprite, for tight rows like a vote tally.
static func crew_dot(npc_id: String, dot_size: int = 30) -> TextureRect:
    var dot := thumb(AstraCrewCatalog.dot_path(npc_id), Vector2(dot_size, dot_size))
    dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    return dot

# ---- reading over art ------------------------------------------------------
#
# 0.3.1 drew dialogue straight onto the room background. Light text over a
# bright console or a white uniform simply disappeared. Every block of prose
# that sits over art now goes inside one of these: an opaque-enough panel with
# its own dark fill, sized so the line length stays readable.
static func reading_panel(accent: Color = CYAN, opacity: float = 0.94) -> PanelContainer:
    var card := PanelContainer.new()
    var box := style(Color(0.016, 0.031, 0.062, opacity), Color(accent, 0.45), 12, 1, 18)
    box.shadow_color = Color(0, 0, 0, 0.55)
    box.shadow_size = 10
    card.add_theme_stylebox_override("panel", box)
    return card

# The standing dialogue box: speaker row (sprite + name + job) above the line,
# on a dark panel, with the text capped at a readable width.
static func dialogue_box(npc_id: String, speaker_name: String, text: String, accent: Color, tag: String = "") -> PanelContainer:
    var card := reading_panel(accent)
    var box := vbox(8)
    card.add_child(box)
    var head := hbox(8)
    box.add_child(head)
    if npc_id != "":
        head.add_child(crew_dot(npc_id, 34))
    head.add_child(label(speaker_name, T_HEAD, accent))
    if npc_id != "":
        head.add_child(label("(%s)" % str(AstraCrewCatalog.info(npc_id).get("job", "")), T_META, MUTED))
    if tag != "":
        head.add_child(spacer())
        head.add_child(chip(tag, accent, T_META - 2))
    var body := prose(text, T_BODY, TEXT)
    body.custom_minimum_size.x = 0
    box.add_child(body)
    return card

# ---- "press here" ----------------------------------------------------------
#
# During the tutorial the player should not have to hunt for the one control
# that matters. This puts a steady accent ring and a caret on it. It is a static
# ring rather than a blinking one: something flashing in the corner of the eye
# while you are reading is the problem, not the solution.
static func mark_as_target(control: Control, accent: Color = GOLD, caption: String = "여기") -> void:
    if control == null:
        return
    var ring := style(Color(accent, 0.22), accent, 8, 3, 10)
    ring.content_margin_top = 6
    ring.content_margin_bottom = 6
    if control is Button:
        control.add_theme_stylebox_override("normal", ring)
        var hover := ring.duplicate() as StyleBoxFlat
        hover.bg_color = Color(accent, 0.38)
        control.add_theme_stylebox_override("hover", hover)
        control.add_theme_color_override("font_color", Color.WHITE)
        if caption != "" and not control.text.begins_with("▶"):
            control.text = "▶  " + control.text
    elif control is PanelContainer:
        control.add_theme_stylebox_override("panel", ring)

# Named wrapper pair so call sites read as intent ("nudge this button") rather
# than as styling, and so every screen shares one on/off switch instead of
# hand-rolling its own highlight. `enabled` lets a caller pass a condition
# straight through without an if/else at every call site.
static func set_tutorial_nudge(control: Control, enabled: bool, accent: Color = GOLD) -> void:
    if enabled:
        mark_as_target(control, accent, "")
    else:
        clear_tutorial_nudge(control)

static func clear_tutorial_nudge(control: Control) -> void:
    if control == null:
        return
    if control is Button:
        control.remove_theme_stylebox_override("normal")
        control.remove_theme_stylebox_override("hover")
        control.remove_theme_color_override("font_color")
        if control.text.begins_with("▶  "):
            control.text = control.text.substr(3)
    elif control is PanelContainer:
        control.remove_theme_stylebox_override("panel")

# ---- who suspects whom -----------------------------------------------------
#
# Eight people each holding an opinion about seven others is fifty-six
# relationships. Nobody is holding that in their head, and asking them to is not
# difficulty, it is bookkeeping. This card answers "what does this person think,
# and why" in three lines, in words, with no numbers.
static func relation_card(session, observer_id: String) -> PanelContainer:
    var data: Dictionary = session.relations_of(observer_id)
    var accent := AstraCrewCatalog.accent(observer_id)
    var card := panel(Color(0.016, 0.031, 0.062, 0.92), Color(accent, 0.32), 10, 12)
    var box := vbox(6)
    card.add_child(box)
    var head := hbox(8)
    box.add_child(head)
    head.add_child(crew_tag(observer_id, T_BODY, true, 26))
    head.add_child(spacer())
    head.add_child(chip(str(data.get("mood", "")), accent, T_META - 2))
    if data.is_empty():
        box.add_child(label("이 사람은 더 이상 회의에 참여하지 않습니다.", T_META, DIM))
        return card

    var watching: Array = data.get("watching", [])
    if watching.is_empty():
        box.add_child(label("아직 특정한 누군가를 의심하지 않습니다.", T_META, DIM))
    else:
        for entry in watching:
            var row := hbox(6)
            box.add_child(row)
            row.add_child(label("→", T_META, RED))
            row.add_child(crew_dot(str(entry["id"]), 22))
            row.add_child(label(AstraCrewCatalog.display_name(str(entry["id"])), T_META, AstraCrewCatalog.accent(str(entry["id"]))))
            row.add_child(label("· %s" % str(entry["strength"]), T_META, RED))
            var why := label("(%s)" % str(entry["reason"]), T_META, MUTED, true)
            row.add_child(why)
    for entry in data.get("leaning", []):
        var row := hbox(6)
        box.add_child(row)
        row.add_child(label("♦", T_META, GREEN))
        row.add_child(crew_dot(str(entry["id"]), 22))
        row.add_child(label(AstraCrewCatalog.display_name(str(entry["id"])), T_META, AstraCrewCatalog.accent(str(entry["id"]))))
        row.add_child(label("· 편을 드는 쪽 (%s)" % str(entry["reason"]), T_META, GREEN, true))
    if int(data.get("retracted", 0)) > 0:
        box.add_child(label("공개 발언을 %d번 되돌린 적이 있습니다." % int(data["retracted"]), T_META, GOLD))
    return card
