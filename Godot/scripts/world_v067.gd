extends "res://scripts/world_v065.gd"

# Hash Race v0.067 mining-operations widget pass.
# Adds the approved six-card draggable HUD while keeping every number bound to
# the actual live company simulation.
const MiningOpsWidget = preload("res://scripts/mining_ops_widget.gd")
const MINING_OPS_WIDGET_REVISION: int = 1

var mining_ops_layer: CanvasLayer
var mining_ops_widget: Control
var mining_ops_restore_button: Button

func _ready() -> void:
    super._ready()
    _install_mining_ops_widget()
    set_meta("hashrace_mining_ops_widget_revision", MINING_OPS_WIDGET_REVISION)

func _install_mining_ops_widget() -> void:
    mining_ops_layer = CanvasLayer.new()
    mining_ops_layer.name = "MiningOpsHUD"
    mining_ops_layer.layer = 26
    add_child(mining_ops_layer)

    mining_ops_widget = MiningOpsWidget.new()
    mining_ops_layer.add_child(mining_ops_widget)
    mining_ops_widget.call("setup", self)
    mining_ops_widget.connect("close_requested", Callable(self, "_on_mining_ops_widget_closed"))

    mining_ops_restore_button = Button.new()
    mining_ops_restore_button.name = "MiningOpsRestore"
    mining_ops_restore_button.text = "OPS"
    mining_ops_restore_button.size = Vector2(54.0, 28.0)
    mining_ops_restore_button.tooltip_text = "Restore the live Mining Ops widget."
    mining_ops_restore_button.add_theme_font_size_override("font_size", 9)
    mining_ops_restore_button.visible = false
    mining_ops_restore_button.pressed.connect(_restore_mining_ops_widget)
    mining_ops_layer.add_child(mining_ops_restore_button)

    if is_instance_valid(energy_status_label):
        energy_status_label.visible = false

    get_viewport().size_changed.connect(_layout_mining_ops_widget)
    _layout_mining_ops_widget()
    mining_ops_widget.call("force_refresh")

func _layout_mining_ops_widget() -> void:
    if not is_instance_valid(mining_ops_widget):
        return
    var viewport_size: Vector2 = get_viewport_rect().size
    mining_ops_widget.call("set_screen_scale", viewport_size)
    if is_instance_valid(mining_ops_restore_button):
        mining_ops_restore_button.position = Vector2(maxf(8.0, viewport_size.x - 64.0), 84.0)

func _on_mining_ops_widget_closed() -> void:
    if is_instance_valid(mining_ops_restore_button):
        mining_ops_restore_button.visible = true

func _restore_mining_ops_widget() -> void:
    if not is_instance_valid(mining_ops_widget):
        return
    mining_ops_widget.show()
    mining_ops_widget.call("force_refresh")
    if is_instance_valid(mining_ops_restore_button):
        mining_ops_restore_button.visible = false

func _refresh_ui() -> void:
    super._refresh_ui()
    if is_instance_valid(mining_ops_widget):
        mining_ops_widget.call("force_refresh")

func debug_mining_ops_widget_ready() -> bool:
    if not is_instance_valid(mining_ops_widget):
        return false
    var snapshot: Dictionary = mining_ops_widget.call("snapshot")
    return snapshot.size() >= 7 and snapshot.has("hashrate") and snapshot.has("power") and snapshot.has("efficiency") and snapshot.has("uptime") and snapshot.has("btc") and snapshot.has("cash")

func debug_mining_ops_widget_snapshot() -> Dictionary:
    if not is_instance_valid(mining_ops_widget):
        return {}
    return mining_ops_widget.call("snapshot")
