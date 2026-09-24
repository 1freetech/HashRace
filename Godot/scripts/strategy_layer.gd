extends Control

var game: Node
var panel: PanelContainer
var toggle_button: Button
var priority_label: Label
var lab_label: Label
var objective_label: Label
var journal_label: Label

var active_priority := "Balanced"
var lab_focus := "Balanced"
var season_objective: Dictionary = {}
var journal_entries: Array[String] = []

var initialized_player := false
var last_season := 0
var last_generation := 0
var last_partner_keys: Array = []
var last_acquired_count := 0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    game = get_node("../HashRace")
    build_overlay()
    set_process(true)

func build_overlay() -> void:
    toggle_button = Button.new()
    toggle_button.text = "Strategy Layer"
    toggle_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    toggle_button.offset_left = -160.0
    toggle_button.offset_top = -54.0
    toggle_button.offset_right = -16.0
    toggle_button.offset_bottom = -14.0
    toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
    toggle_button.pressed.connect(toggle_panel)
    add_child(toggle_button)

    panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    panel.offset_left = -500.0
    panel.offset_top = -540.0
    panel.offset_right = -16.0
    panel.offset_bottom = -64.0
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    panel.visible = false
    add_child(panel)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 8)
    panel.add_child(content)

    var title := Label.new()
    title.text = "HASH RACE — strategy layer"
    title.add_theme_font_size_override("font_size", 20)
    content.add_child(title)

    var note := Label.new()
    note.text = "Give the site a high-level priority, preview the next ASIC generation, and chase one clear season objective. The mine keeps running underneath these choices."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(note)

    priority_label = Label.new()
    content.add_child(priority_label)
    var priority_row := HBoxContainer.new()
    content.add_child(priority_row)
    add_small_button(priority_row, "Balanced", func(): set_priority("Balanced"))
    add_small_button(priority_row, "Efficiency", func(): set_priority("Efficiency"))
    add_small_button(priority_row, "Reliability", func(): set_priority("Reliability"))
    add_small_button(priority_row, "R&D", func(): set_priority("R&D"))

    var divider_a := HSeparator.new()
    content.add_child(divider_a)

    lab_label = Label.new()
    content.add_child(lab_label)
    var lab_row := HBoxContainer.new()
    content.add_child(lab_row)
    add_small_button(lab_row, "Balanced", func(): set_lab_focus("Balanced"))
    add_small_button(lab_row, "Throughput", func(): set_lab_focus("Throughput"))
    add_small_button(lab_row, "Efficiency", func(): set_lab_focus("Efficiency"))
    add_small_button(lab_row, "Reliability", func(): set_lab_focus("Reliability"))
    var preview := Button.new()
    preview.text = "Preview next ASIC before funding it"
    preview.pressed.connect(preview_next_generation)
    content.add_child(preview)

    var divider_b := HSeparator.new()
    content.add_child(divider_b)

    objective_label = Label.new()
    objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(objective_label)

    var divider_c := HSeparator.new()
    content.add_child(divider_c)

    var journal_title := Label.new()
    journal_title.text = "Company journal"
    journal_title.add_theme_font_size_override("font_size", 16)
    content.add_child(journal_title)
    journal_label = Label.new()
    journal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(journal_label)

func add_small_button(row: HBoxContainer, text: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = text
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(callback)
    row.add_child(button)

func toggle_panel() -> void:
    panel.visible = not panel.visible
    toggle_button.text = "Close Strategy" if panel.visible else "Strategy Layer"

func _process(_delta: float) -> void:
    if game == null or game.player.is_empty():
        if is_instance_valid(toggle_button):
            toggle_button.disabled = true
        return

    toggle_button.disabled = false
    if not initialized_player:
        initialize_for_player()
        return

    if game.generation != last_generation:
        apply_lab_focus_to_new_generation()
        last_generation = game.generation
        add_journal("Gen %d hardware entered service with %s lab focus." % [game.generation, lab_focus])

    var partner_keys: Array = game.signed_partners.keys()
    if partner_keys.size() > last_partner_keys.size():
        for sector in partner_keys:
            if not last_partner_keys.has(sector):
                add_journal("Signed a new %s partnership." % sector)
        last_partner_keys = partner_keys.duplicate()

    var acquired_count := count_acquired_rivals()
    if acquired_count > last_acquired_count:
        add_journal("Completed a rival mining-company acquisition.")
        last_acquired_count = acquired_count

    if game.season != last_season:
        evaluate_season_objective()
        last_season = game.season
        create_season_objective()
        add_journal("Season %d opened with a new operating objective." % game.season)

    refresh_overlay_text()

func initialize_for_player() -> void:
    initialized_player = true
    last_season = game.season
    last_generation = game.generation
    last_partner_keys = game.signed_partners.keys().duplicate()
    last_acquired_count = count_acquired_rivals()
    add_journal("%s entered the Hash Race." % game.player.name)
    create_season_objective()
    refresh_overlay_text()

func set_priority(new_priority: String) -> void:
    if not initialized_player or new_priority == active_priority:
        return
    remove_priority_effects()
    active_priority = new_priority
    apply_priority_effects()
    game.set_status("Site priority changed to %s." % active_priority)
    add_journal("Operations priority changed to %s." % active_priority)
    game.refresh_all()
    refresh_overlay_text()

func remove_priority_effects() -> void:
    match active_priority:
        "Efficiency":
            game.efficiency_jth /= 0.96
            game.uptime += 0.008
        "Reliability":
            game.uptime -= 0.012
            game.efficiency_jth /= 1.04
        "R&D":
            game.player.rd_bonus -= 0.15
            game.uptime += 0.005

func apply_priority_effects() -> void:
    match active_priority:
        "Efficiency":
            game.efficiency_jth *= 0.96
            game.uptime -= 0.008
        "Reliability":
            game.uptime += 0.012
            game.efficiency_jth *= 1.04
        "R&D":
            game.player.rd_bonus += 0.15
            game.uptime -= 0.005

func set_lab_focus(new_focus: String) -> void:
    lab_focus = new_focus
    game.set_status("ASIC lab focus set to %s for the next generation." % lab_focus)
    add_journal("ASIC lab focus set to %s." % lab_focus)
    preview_next_generation()

func preview_next_generation() -> void:
    if not initialized_player:
        return
    var next_hash := game.machine_hashrate_th * 2.2
    var next_eff := game.efficiency_jth * 0.72
    var next_uptime := game.effective_uptime()
    if game.signed_partners.has("Semiconductor"):
        next_eff *= 0.90
    match lab_focus:
        "Throughput":
            next_hash *= 1.10
            next_eff *= 1.03
        "Efficiency":
            next_hash *= 0.96
            next_eff *= 0.93
        "Reliability":
            next_hash *= 0.98
            next_eff *= 0.98
            next_uptime = min(0.995, next_uptime + 0.004)
    game.set_status("ASIC preview — Gen %d: %.1f TH/s, %.2f J/TH, %.1f%% uptime with %s focus." % [game.generation + 1, next_hash, next_eff, next_uptime * 100.0, lab_focus])

func apply_lab_focus_to_new_generation() -> void:
    match lab_focus:
        "Throughput":
            game.machine_hashrate_th *= 1.10
            game.efficiency_jth *= 1.03
        "Efficiency":
            game.machine_hashrate_th *= 0.96
            game.efficiency_jth *= 0.93
        "Reliability":
            game.machine_hashrate_th *= 0.98
            game.efficiency_jth *= 0.98
            game.uptime = min(0.99, game.uptime + 0.004)
    game.refresh_all()

func create_season_objective() -> void:
    var selector := game.season % 4
    match selector:
        0:
            season_objective = {
                "type": "fleet",
                "target": game.fleet + 2,
                "text": "Add 2 ASICs before the next season review."
            }
        1:
            season_objective = {
                "type": "partner",
                "target": game.signed_partners.size() + 1,
                "text": "Sign at least 1 new outside NPC partner."
            }
        2:
            season_objective = {
                "type": "generation",
                "target": game.generation + 1,
                "text": "Advance the ASIC program by 1 generation."
            }
        _:
            var current_rank := game.calculate_rank()
            season_objective = {
                "type": "rank",
                "target": max(1, current_rank - 1),
                "start_rank": current_rank,
                "text": "Improve the mining-league rank by at least 1 place."
            }

func objective_is_complete() -> bool:
    if season_objective.is_empty():
        return false
    match season_objective.type:
        "fleet":
            return game.fleet >= int(season_objective.target)
        "partner":
            return game.signed_partners.size() >= int(season_objective.target)
        "generation":
            return game.generation >= int(season_objective.target)
        "rank":
            return game.calculate_rank() <= int(season_objective.target)
    return false

func evaluate_season_objective() -> void:
    if season_objective.is_empty():
        return
    if objective_is_complete():
        var bonus := 2500.0 + float(game.season) * 1000.0
        game.cash += bonus
        game.prestige += 2
        add_journal("Season objective completed: +$%d and +2 prestige." % int(bonus))
        game.set_status("Season objective completed. Bonus: $%d and +2 prestige." % int(bonus))
        game.refresh_all()
    else:
        add_journal("Season objective missed. No penalty; the next objective is ready.")

func objective_progress_text() -> String:
    if season_objective.is_empty():
        return "Season objective: waiting for company selection."
    var done := objective_is_complete()
    var progress := ""
    match season_objective.type:
        "fleet":
            progress = "%d / %d ASICs" % [game.fleet, int(season_objective.target)]
        "partner":
            progress = "%d / %d partners" % [game.signed_partners.size(), int(season_objective.target)]
        "generation":
            progress = "Gen %d / Gen %d" % [game.generation, int(season_objective.target)]
        "rank":
            progress = "Rank #%d / target #%d" % [game.calculate_rank(), int(season_objective.target)]
    return "Season objective: %s\nProgress: %s%s" % [season_objective.text, progress, " — COMPLETE" if done else ""]

func count_acquired_rivals() -> int:
    var count := 0
    for rival in game.rivals:
        if rival.acquired:
            count += 1
    return count

func add_journal(text: String) -> void:
    var stamped := "S%d D%d — %s" % [game.season, game.day, text]
    journal_entries.push_front(stamped)
    while journal_entries.size() > 6:
        journal_entries.pop_back()
    if is_instance_valid(journal_label):
        journal_label.text = "\n".join(journal_entries)

func refresh_overlay_text() -> void:
    if not initialized_player:
        return
    priority_label.text = "Operations priority: %s\nBalanced = no modifier. Efficiency lowers J/TH but trims uptime. Reliability raises uptime but uses more power. R&D accelerates research but slightly reduces uptime." % active_priority
    lab_label.text = "ASIC lab focus: %s\nChoose one tradeoff for the next hardware generation, then preview it before committing R&D money." % lab_focus
    objective_label.text = objective_progress_text()
    journal_label.text = "\n".join(journal_entries)
