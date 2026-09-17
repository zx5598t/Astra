class_name AstraModal
extends Control

# Dimmed full-screen dialog. Buttons report their index; Esc or clicking the
# dim area reports -1 when the dialog is dismissible.

signal closed(choice: int)

var dismissible: bool = true
var _callback: Callable

static func open(host: Node, title: String, content: Control, buttons: Array, callback: Callable = Callable(), width: float = 640.0, can_dismiss: bool = true) -> AstraModal:
    var modal := AstraModal.new()
    modal.dismissible = can_dismiss
    modal._callback = callback
    host.add_child(modal)
    modal._build(title, content, buttons, width)
    return modal

func _build(title: String, content: Control, buttons: Array, width: float) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var dim := ColorRect.new()
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0.0, 0.01, 0.03, 0.72)
    dim.gui_input.connect(_on_dim_input)
    add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(center)
    var card := AstraUI.panel(AstraUI.PANEL, AstraUI.BORDER_HI, 14, 22)
    card.custom_minimum_size = Vector2(width, 0)
    center.add_child(card)
    var box := AstraUI.vbox(14)
    card.add_child(box)
    if title != "":
        box.add_child(AstraUI.label(title, 22, AstraUI.TEXT))
    if content != null:
        box.add_child(content)
    if not buttons.is_empty():
        var row := AstraUI.hbox(10)
        row.alignment = BoxContainer.ALIGNMENT_END
        box.add_child(row)
        for index in range(buttons.size()):
            var spec = buttons[index]
            var text := str(spec)
            var accent := AstraUI.CYAN
            if spec is Array:
                text = str(spec[0])
                accent = spec[1]
            var button := AstraUI.button(text, accent, 16, 46, index == buttons.size() - 1)
            button.custom_minimum_size = Vector2(150, 46)
            button.pressed.connect(close.bind(index))
            row.add_child(button)
    modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.12)

func close(choice: int) -> void:
    if is_queued_for_deletion():
        return
    closed.emit(choice)
    if _callback.is_valid():
        _callback.call(choice)
    queue_free()

func _on_dim_input(event: InputEvent) -> void:
    if dismissible and event is InputEventMouseButton and event.pressed:
        close(-1)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        if dismissible:
            close(-1)
