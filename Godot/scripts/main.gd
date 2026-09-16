extends Control

const STARTING_MINERS := [
    {"name":"Emberline Compute","trait":"Low-cost operator","cash":9000.0,"fleet":5,"jth":82.0,"power_discount":0.10,"rd_bonus":0.00,"uptime_bonus":0.00,"acquisition_discount":0.00,"site_bonus":0.00},
    {"name":"Helix Circuit Labs","trait":"Research-first miner","cash":9500.0,"fleet":3,"jth":78.0,"power_discount":0.00,"rd_bonus":0.25,"uptime_bonus":0.00,"acquisition_discount":0.00,"site_bonus":0.00},
    {"name":"ArcCurrent Systems","trait":"Grid-optimization specialist","cash":8500.0,"fleet":4,"jth":80.0,"power_discount":0.16,"rd_bonus":0.00,"uptime_bonus":0.00,"acquisition_discount":0.00,"site_bonus":0.00},
    {"name":"StoneGrid Infrastructure","trait":"Land-and-site scaler","cash":10000.0,"fleet":3,"jth":84.0,"power_discount":0.00,"rd_bonus":0.00,"uptime_bonus":0.00,"acquisition_discount":0.00,"site_bonus":0.20},
    {"name":"Meridian Node Group","trait":"Deal-focused consolidator","cash":15000.0,"fleet":2,"jth":86.0,"power_discount":0.00,"rd_bonus":0.00,"uptime_bonus":0.00,"acquisition_discount":0.18,"site_bonus":0.00},
    {"name":"BlueLoop Compute","trait":"Cooling and uptime specialist","cash":9000.0,"fleet":3,"jth":76.0,"power_discount":0.00,"rd_bonus":0.00,"uptime_bonus":0.025,"acquisition_discount":0.00,"site_bonus":0.00},
    {"name":"SignalPeak Systems","trait":"Reliability-first operator","cash":9000.0,"fleet":4,"jth":83.0,"power_discount":0.00,"rd_bonus":0.00,"uptime_bonus":0.018,"acquisition_discount":0.00,"site_bonus":0.00},
    {"name":"Parallax Digital Works","trait":"Balanced industrial miner","cash":10500.0,"fleet":3,"jth":79.0,"power_discount":0.05,"rd_bonus":0.08,"uptime_bonus":0.005,"acquisition_discount":0.00,"site_bonus":0.05},
    {"name":"Lattice Energy Labs","trait":"Efficiency-focused fleet manager","cash":8000.0,"fleet":3,"jth":72.0,"power_discount":0.00,"rd_bonus":0.10,"uptime_bonus":0.00,"acquisition_discount":0.00,"site_bonus":0.00},
    {"name":"Epoch Harbor Holdings","trait":"Capital-heavy expansion miner","cash":13500.0,"fleet":3,"jth":88.0,"power_discount":0.00,"rd_bonus":0.00,"uptime_bonus":0.00,"acquisition_discount":0.08,"site_bonus":0.15}
]

const PARTNERS := [
    {"sector":"AI","name":"NeuralPeak AI","cost":30000.0,"effect":"R&D + compute-contract cash","cash_bonus":2500.0,"rd":0.30,"uptime":0.0,"power":0.0,"site":0.0,"acq":0.0},
    {"sector":"Robotics","name":"Atlas Robotics","cost":45000.0,"effect":"Automation raises uptime","cash_bonus":1000.0,"rd":0.0,"uptime":0.025,"power":0.0,"site":0.0,"acq":0.0},
    {"sector":"Semiconductor","name":"SilicaWorks Foundry","cost":80000.0,"effect":"Better chips lower J/TH","cash_bonus":0.0,"rd":0.15,"uptime":0.0,"power":0.0,"site":0.0,"acq":0.0},
    {"sector":"Energy","name":"VoltRiver Energy","cost":50000.0,"effect":"Lower electricity price","cash_bonus":0.0,"rd":0.0,"uptime":0.0,"power":0.22,"site":0.0,"acq":0.0},
    {"sector":"Telecom","name":"FiberGrid Communications","cost":40000.0,"effect":"Network reliability boosts uptime","cash_bonus":1000.0,"rd":0.0,"uptime":0.015,"power":0.0,"site":0.0,"acq":0.0},
    {"sector":"Real Estate","name":"MetroLand Development","cost":65000.0,"effect":"More land and site capacity","cash_bonus":0.0,"rd":0.0,"uptime":0.0,"power":0.0,"site":0.30,"acq":0.0},
    {"sector":"Finance","name":"Frontier Capital","cost":90000.0,"effect":"Cheaper acquisitions","cash_bonus":0.0,"rd":0.0,"uptime":0.0,"power":0.0,"site":0.0,"acq":0.20},
    {"sector":"Infrastructure","name":"SkyStack Infrastructure","cost":120000.0,"effect":"Bigger sites and cheaper expansion","cash_bonus":0.0,"rd":0.0,"uptime":0.0,"power":0.0,"site":0.35,"acq":0.0},
    {"sector":"Quick Service","name":"QuickBite Franchise Network","cost":35000.0,"effect":"Recurring commercial cash","cash_bonus":3500.0,"rd":0.0,"uptime":0.0,"power":0.0,"site":0.0,"acq":0.0},
    {"sector":"Sports","name":"Pro Sports Alliance","cost":70000.0,"effect":"Sponsorship cash and franchise prestige","cash_bonus":5000.0,"rd":0.0,"uptime":0.0,"power":0.0,"site":0.0,"acq":0.0}
]

var player := {}
var rivals: Array = []
var signed_partners: Dictionary = {}
var day := 0
var season := 1
var cash := 0.0
var fleet := 0
var machine_hashrate_th := 5.0
var efficiency_jth := 85.0
var electricity_price := 0.060
var uptime := 0.955
var research := 0.0
var research_target := 15000.0
var generation := 1
var site_capacity_mw := 0.05
var prestige := 50

var status_label: Label
var stats_label: Label
var standings_box: VBoxContainer
var partner_box: VBoxContainer
var action_box: VBoxContainer

func _ready() -> void:
    show_company_select()

func clear_ui() -> void:
    for child in get_children():
        child.queue_free()

func show_company_select() -> void:
    clear_ui()
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 10)
    add_child(root)

    var title := Label.new()
    title.text = "HASH RACE — choose your Bitcoin mining company"
    title.add_theme_font_size_override("font_size", 26)
    root.add_child(title)

    var intro := Label.new()
    intro.text = "Every team in the Hash Race is a Bitcoin miner. Outside industries become NPC partners later."
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(intro)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(list)

    for profile in STARTING_MINERS:
        var button := Button.new()
        button.text = "%s — %s | $%d | %d miners | %.0f J/TH" % [profile.name, profile.trait, int(profile.cash), int(profile.fleet), float(profile.jth)]
        button.custom_minimum_size = Vector2(0, 48)
        button.pressed.connect(func(p = profile): select_company(p))
        list.add_child(button)

func select_company(profile: Dictionary) -> void:
    player = profile.duplicate(true)
    cash = player.cash
    fleet = player.fleet
    efficiency_jth = player.jth
    uptime = min(0.99, 0.955 + player.uptime_bonus)
    site_capacity_mw = 0.05 * (1.0 + player.site_bonus)
    day = 0
    season = 1
    generation = 1
    research = 0.0
    research_target = 15000.0
    signed_partners.clear()
    rivals.clear()
    for profile_data in STARTING_MINERS:
        if profile_data.name != player.name:
            rivals.append({
                "name": profile_data.name,
                "hashrate": float(profile_data.fleet) * 5.0,
                "value": float(profile_data.cash) + float(profile_data.fleet) * 1200.0,
                "jth": float(profile_data.jth),
                "acquired": false
            })
    build_game_ui()
    refresh_all()

func build_game_ui() -> void:
    clear_ui()
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 8)
    add_child(root)

    var header := HBoxContainer.new()
    root.add_child(header)
    var title := Label.new()
    title.text = "HASH RACE — %s" % player.name
    title.add_theme_font_size_override("font_size", 24)
    header.add_child(title)
    status_label = Label.new()
    status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header.add_child(status_label)

    stats_label = Label.new()
    stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(stats_label)

    var columns := HBoxContainer.new()
    columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(columns)

    action_box = VBoxContainer.new()
    action_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(action_box)
    var action_title := Label.new()
    action_title.text = "Mining operations"
    action_title.add_theme_font_size_override("font_size", 20)
    action_box.add_child(action_title)
    add_action("Advance 1 day", advance_day)
    add_action("Buy current ASIC", buy_miner)
    add_action("Fund R&D", fund_research)
    add_action("Expand mining site", expand_site)

    partner_box = VBoxContainer.new()
    partner_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(partner_box)

    standings_box = VBoxContainer.new()
    standings_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(standings_box)

func add_action(text: String, callback: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0, 44)
    b.pressed.connect(callback)
    action_box.add_child(b)

func total_hashrate() -> float:
    return float(fleet) * machine_hashrate_th

func power_kw() -> float:
    return total_hashrate() * efficiency_jth / 1000.0

func effective_electricity_price() -> float:
    var discount := float(player.power_discount)
    if signed_partners.has("Energy"):
        discount += 0.22
    return max(0.012, electricity_price * (1.0 - min(0.60, discount)))

func effective_uptime() -> float:
    var bonus := 0.0
    if signed_partners.has("Robotics"):
        bonus += 0.025
    if signed_partners.has("Telecom"):
        bonus += 0.015
    return min(0.995, uptime + bonus)

func daily_profit() -> float:
    var revenue := total_hashrate() * 2.25 * effective_uptime()
    var power_cost := power_kw() * 24.0 * effective_electricity_price() * effective_uptime()
    var operations := float(fleet) * 1.5
    var partner_cash := 0.0
    for partner in PARTNERS:
        if signed_partners.has(partner.sector):
            partner_cash += float(partner.cash_bonus) / 30.0
    return revenue + partner_cash - power_cost - operations

func site_power_limit_kw() -> float:
    return site_capacity_mw * 1000.0

func can_add_miner() -> bool:
    return power_kw() + machine_hashrate_th * efficiency_jth / 1000.0 <= site_power_limit_kw()

func buy_miner() -> void:
    var price := 650.0 * pow(1.9, generation - 1)
    if cash < price:
        set_status("Not enough cash for the current ASIC.")
        return
    if not can_add_miner():
        set_status("Site is full. Expand power capacity first.")
        return
    cash -= price
    fleet += 1
    set_status("Added one Gen %d ASIC." % generation)
    refresh_all()

func fund_research() -> void:
    if cash <= 0.0:
        set_status("No cash available for R&D.")
        return
    var spend := min(cash, max(1000.0, research_target * 0.20))
    var multiplier := 1.0 + float(player.rd_bonus)
    if signed_partners.has("AI"):
        multiplier += 0.30
    if signed_partners.has("Semiconductor"):
        multiplier += 0.15
    cash -= spend
    research += spend * multiplier
    if research >= research_target:
        research = 0.0
        generation += 1
        machine_hashrate_th *= 2.2
        efficiency_jth = max(0.75, efficiency_jth * 0.72)
        if signed_partners.has("Semiconductor"):
            efficiency_jth *= 0.90
        research_target *= 3.0
        set_status("Hardware evolution unlocked: Gen %d at %.1f TH/s and %.2f J/TH." % [generation, machine_hashrate_th, efficiency_jth])
    else:
        set_status("R&D funded. Progress is now $%d / $%d." % [int(research), int(research_target)])
    refresh_all()

func expand_site() -> void:
    var base_cost := 12000.0 * (site_capacity_mw / 0.05)
    var site_bonus := float(player.site_bonus)
    if signed_partners.has("Real Estate"):
        site_bonus += 0.30
    if signed_partners.has("Infrastructure"):
        site_bonus += 0.35
    var cost := base_cost * max(0.45, 1.0 - site_bonus * 0.35)
    if cash < cost:
        set_status("Need $%d to expand the site." % int(cost))
        return
    cash -= cost
    site_capacity_mw *= 1.75 + site_bonus * 0.20
    set_status("Site expanded to %.2f MW." % site_capacity_mw)
    refresh_all()

func advance_day() -> void:
    day += 1
    cash += daily_profit()
    for rival in rivals:
        if rival.acquired:
            continue
        rival.hashrate *= 1.0 + randf_range(0.001, 0.010)
        rival.value *= 1.0 + randf_range(-0.003, 0.012)
        if randf() < 0.02:
            rival.jth = max(0.75, rival.jth * 0.97)
    if day % 90 == 0:
        season += 1
        prestige += 1
        set_status("Season %d started. Rival companies have advanced too." % season)
    else:
        set_status("Day %d complete. Profit: $%d." % [day, int(daily_profit())])
    refresh_all()

func sign_partner(partner: Dictionary) -> void:
    if signed_partners.has(partner.sector):
        set_status("You already have a %s partner." % partner.sector)
        return
    if cash < partner.cost:
        set_status("Need $%d for the %s partnership." % [int(partner.cost), partner.sector])
        return
    cash -= partner.cost
    signed_partners[partner.sector] = partner.name
    if partner.sector == "Sports":
        prestige += 5
    set_status("Partnership signed: %s (%s)." % [partner.name, partner.sector])
    refresh_all()

func try_acquire(rival: Dictionary) -> void:
    if rival.acquired:
        return
    var discount := float(player.acquisition_discount)
    if signed_partners.has("Finance"):
        discount += 0.20
    var price := rival.value * 1.15 * max(0.55, 1.0 - discount)
    if cash < price:
        set_status("Need $%d to acquire %s." % [int(price), rival.name])
        return
    cash -= price
    rival.acquired = true
    fleet += max(1, int(round(rival.hashrate / machine_hashrate_th)))
    prestige += 3
    set_status("Acquired rival miner %s." % rival.name)
    refresh_all()

func refresh_all() -> void:
    if not is_instance_valid(stats_label):
        return
    var rank := calculate_rank()
    stats_label.text = "Season %d | Day %d | Rank #%d/10 | Prestige %d | Cash $%d | Fleet %d | Hashrate %.1f TH/s | %.2f J/TH | Power %.1f kW / %.0f kW site | Uptime %.1f%% | Est. profit/day $%d" % [season, day, rank, prestige, int(cash), fleet, total_hashrate(), efficiency_jth, power_kw(), site_power_limit_kw(), effective_uptime() * 100.0, int(daily_profit())]
    rebuild_partners()
    rebuild_standings()

func rebuild_partners() -> void:
    for child in partner_box.get_children():
        child.queue_free()
    var title := Label.new()
    title.text = "External NPC partners"
    title.add_theme_font_size_override("font_size", 20)
    partner_box.add_child(title)
    for partner in PARTNERS:
        var b := Button.new()
        var owned := signed_partners.has(partner.sector)
        b.text = "%s — %s\n%s%s" % [partner.sector, partner.name, partner.effect, " [SIGNED]" if owned else " — $%d" % int(partner.cost)]
        b.disabled = owned
        b.pressed.connect(func(p = partner): sign_partner(p))
        partner_box.add_child(b)

func rebuild_standings() -> void:
    for child in standings_box.get_children():
        child.queue_free()
    var title := Label.new()
    title.text = "Bitcoin mining league"
    title.add_theme_font_size_override("font_size", 20)
    standings_box.add_child(title)

    var board := []
    board.append({"name":player.name,"hashrate":total_hashrate(),"player":true,"acquired":false,"ref":null})
    for rival in rivals:
        board.append({"name":rival.name,"hashrate":rival.hashrate,"player":false,"acquired":rival.acquired,"ref":rival})
    board.sort_custom(func(a, b): return a.hashrate > b.hashrate)

    var position := 1
    for entry in board:
        var row := HBoxContainer.new()
        var label := Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.text = "%d. %s — %.1f TH/s%s" % [position, entry.name, entry.hashrate, " [YOU]" if entry.player else (" [ACQUIRED]" if entry.acquired else "")]
        row.add_child(label)
        if not entry.player and not entry.acquired:
            var acquire := Button.new()
            acquire.text = "Acquire"
            acquire.pressed.connect(func(r = entry.ref): try_acquire(r))
            row.add_child(acquire)
        standings_box.add_child(row)
        position += 1

func calculate_rank() -> int:
    var higher := 0
    for rival in rivals:
        if not rival.acquired and rival.hashrate > total_hashrate():
            higher += 1
    return higher + 1

func set_status(text: String) -> void:
    if is_instance_valid(status_label):
        status_label.text = text