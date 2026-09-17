class_name AstraUI
extends RefCounted

# Shared palette and widget factories. Every screen builds its controls here
# so spacing, colors and button states stay consistent.

const BG := Color("050b16")
const PANEL := Color("0b1627")
const PANEL_2 := Color("0f1d33")
const PANEL_3 := Color("16284a")
const BORDER := Color("223757")
const BORDER_HI := Color("35547f")
const TEXT := Color("e8f1ff")
const MUTED := Color("93a8c6")
const DIM := Color("5d7292")
const CYAN := Color("55d6ff")
const GREEN := Color("5ee3a0")
const RED := Color("ff6f7f")
const GOLD := Color("ffd36a")
const PINK := Color("ff9ed1")
const VIOLET := Color("b88cff")
const NIGHT := Color("8f9cff")

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
    node.add_theme_font_size_override("font_size", size)
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
    node.add_theme_font_size_override("normal_font_size", size)
    node.add_theme_font_size_override("bold_font_size", size)
    node.add_theme_font_size_override("italics_font_size", size)
    node.add_theme_color_override("default_color", TEXT)
    return node

static func button(text: String, accent: Color = CYAN, size: int = 16, min_height: int = 44, filled: bool = false) -> Button:
    var node := Button.new()
    node.text = text
    node.focus_mode = Control.FOCUS_NONE
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
    node.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
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
