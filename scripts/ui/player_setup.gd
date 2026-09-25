class_name AstraPlayerSetup
extends Control

# Choosing the explorer for a new campaign: one of six fixed people, not a
# look or a class. Everything here is the explorer's main illustration
# (플레이어/<이름>.png): each card is a crop of it, the side panel shows it whole
# with their past, why they came and how they approach people. No pixel art on
# this screen — the small pixel self first appears in the deck scenes. No
# stats, no difficulty stars. One confirm starts.

signal confirmed(profile: Dictionary)
signal cancelled

# Legacy looks stay loadable for old saves (see AstraExplorerCatalog.normalize).
const PRESETS := AstraExplorerCatalog.LEGACY_ART

var _selected := "serin"
var _cards: Dictionary = {}
var _detail: VBoxContainer
var _quote: Label
var _figure: TextureRect

func setup(initial: Dictionary = {}) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var bg := AstraUI.thumb(AstraArt.background("medical"), Vector2.ZERO)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    add_child(AstraArt.shade(true))
    var panel := AstraUI.reading_panel(AstraUI.CYAN, 0.96)
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.offset_left = 28
    panel.offset_right = -28
    panel.offset_top = 18
    panel.offset_bottom = -18
    add_child(panel)
    var box := AstraUI.vbox(10)
    panel.add_child(box)
    box.add_child(AstraUI.label("이번 ASTRA를 누구의 눈으로 볼까요", AstraUI.T_TITLE, AstraUI.CYAN))
    box.add_child(AstraUI.prose("같은 진실을 만나는 여섯 탐사요원. 무엇을 먼저 묻는지, 사람에게 어떻게 다가가는지가 다릅니다. 능력의 차이는 없습니다.", AstraUI.T_UI, AstraUI.MUTED))
    var row := AstraUI.hbox(16)
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(row)
    var grid := GridContainer.new()
    grid.columns = 3
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    grid.size_flags_stretch_ratio = 2.2
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    row.add_child(grid)
    for id in AstraExplorerCatalog.ORDER:
        grid.add_child(_card(id))
    var side := AstraUI.vbox(8)
    side.custom_minimum_size.x = 360
    side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    side.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_child(side)
    _figure = AstraUI.thumb("", Vector2(0, 300))
    _figure.name = "MainIllustration"
    _figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _figure.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _figure.size_flags_stretch_ratio = 1.3
    side.add_child(_figure)
    _detail = AstraUI.vbox(8)
    _detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var detail_scroll := AstraUI.scroll(_detail)
    detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    side.add_child(detail_scroll)
    var actions := AstraUI.hbox(12)
    box.add_child(actions)
    var back := AstraUI.button("뒤로", AstraUI.MUTED, AstraUI.T_UI, 46)
    back.pressed.connect(func(): cancelled.emit())
    actions.add_child(back)
    actions.add_child(AstraUI.spacer())
    var go := AstraUI.primary_button("이 탐사요원으로 시작   →", AstraUI.GREEN)
    go.name = "StartButton"
    go.pressed.connect(func(): confirmed.emit(AstraExplorerCatalog.profile_for(_selected)))
    actions.add_child(go)
    _select(str(initial.get("explorer_id", "serin")), false)
    (_cards[_selected] as Button).grab_focus.call_deferred()

func _card(id: String) -> Button:
    var d := AstraExplorerCatalog.data(id)
    var card := Button.new()
    card.name = "Card_" + id
    card.custom_minimum_size = Vector2(200, 250)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.size_flags_vertical = Control.SIZE_EXPAND_FILL
    card.toggle_mode = true
    card.clip_contents = true
    card.tooltip_text = str(d["selection"])
    card.pressed.connect(_select.bind(id, true))
    var content := AstraUI.vbox(2)
    content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    content.offset_left = 8
    content.offset_right = -8
    content.offset_top = 6
    content.offset_bottom = -6
    content.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(content)
    # A crop of the same main illustration: head and shoulders.
    var portrait := TextureRect.new()
    portrait.texture = card_texture(id)
    portrait.custom_minimum_size = Vector2(0, 118)
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(portrait)
    var name_row := AstraUI.hbox(6)
    name_row.add_child(AstraUI.label(str(d["name"]), AstraUI.T_HEAD, AstraUI.TEXT))
    name_row.add_child(AstraUI.label(str(d["latin"]), AstraUI.T_META, AstraUI.DIM))
    content.add_child(name_row)
    content.add_child(AstraUI.label(str(AstraExplorerCatalog.CARD_SPECIALTIES[id]), AstraUI.T_META, AstraUI.CYAN))
    content.add_child(AstraUI.label(str(AstraExplorerCatalog.CARD_SUMMARIES[id]), AstraUI.T_META, AstraUI.MUTED))
    var quote := AstraUI.label("“%s”" % d["selection"], AstraUI.T_META, AstraUI.TEXT, true)
    content.add_child(quote)
    for child in content.get_children():
        child.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_theme_stylebox_override("normal", AstraUI.style(AstraUI.PANEL, AstraUI.BORDER, 8, 1, 6))
    card.add_theme_stylebox_override("hover", AstraUI.style(Color(AstraUI.CYAN, 0.10), Color(AstraUI.CYAN, 0.6), 8, 1, 6))
    card.add_theme_stylebox_override("pressed", AstraUI.style(Color(AstraUI.GOLD, 0.16), AstraUI.GOLD, 8, 3, 6))
    card.add_theme_stylebox_override("hover_pressed", AstraUI.style(Color(AstraUI.GOLD, 0.2), AstraUI.GOLD, 8, 3, 6))
    _cards[id] = card
    return card

func selected() -> String:
    return _selected

# The head-and-shoulders crop of an explorer's main illustration.
static func card_texture(id: String) -> Texture2D:
    var full := AstraUI.texture(AstraExplorerCatalog.full_path(id))
    if full == null:
        return null
    var w := float(full.get_width())
    var h := float(full.get_height())
    var box := minf(w, h * 0.34)
    var atlas := AtlasTexture.new()
    atlas.atlas = full
    atlas.region = Rect2(Vector2((w - box) * 0.5 + float(CARD_SHIFT.get(id, 0)) * box, 0.0), Vector2(box, box))
    return atlas

# Where the face sits in each drawing, as a share of the crop width (the
# figures lean or turn). Checked against every main illustration.
const CARD_SHIFT := {"serin": 0.0, "mika": 0.0, "jace": 0.0, "rael": 0.0, "logan": 0.0, "sia": 0.0}

func _select(id: String, spoken: bool = true) -> void:
    _selected = id if id in AstraExplorerCatalog.ORDER else "serin"
    for key in _cards:
        (_cards[key] as Button).set_pressed_no_signal(key == _selected)
    var d := AstraExplorerCatalog.data(_selected)
    _figure.texture = AstraUI.texture(AstraExplorerCatalog.full_path(_selected))
    AstraUI.clear(_detail)
    var head := AstraUI.hbox(8)
    head.add_child(AstraUI.label(str(d["name"]), AstraUI.T_TITLE, AstraUI.GOLD))
    head.add_child(AstraUI.label(str(d["latin"]), AstraUI.T_UI, AstraUI.DIM))
    _detail.add_child(head)
    _detail.add_child(AstraUI.prose(str(d["specialty"]), AstraUI.T_META, AstraUI.CYAN))
    # The selection line is said when you pick them.
    _quote = AstraUI.prose("“%s”" % d["selection"], AstraUI.T_BODY, AstraUI.TEXT)
    _detail.add_child(_quote)
    if spoken:
        AstraUI.fade_in(_quote, 0.35)
    for pair in [["지나온 길", "background"], ["탐사 지원 사유", "reason"], ["사람을 대하는 방식", "approach"], ["처음 본 승무원들의 인상", "first_impression"]]:
        _detail.add_child(AstraUI.label(str(pair[0]), AstraUI.T_META, AstraUI.CYAN))
        var text := str(d[pair[1]])
        if pair[1] == "reason" or pair[1] == "first_impression":
            text = "“%s”" % text
        _detail.add_child(AstraUI.prose(text, AstraUI.T_UI, AstraUI.MUTED))

