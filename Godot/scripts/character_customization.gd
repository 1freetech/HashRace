extends RefCounted
class_name HashRaceCharacterCustomization

const DEFAULT_SKIN_TONE: int = 2
const DEFAULT_GENDER: int = 0
const DEFAULT_OUTFIT: int = 0
const DEFAULT_SCOUTER_COLOR: int = 0
const DEFAULT_SCOUTER_EYE: int = 1

const SKIN_TONES: Array = [
    {"id":"deep", "name":"Deep", "skin":Color("5d3526"), "highlight":Color("875239")},
    {"id":"rich", "name":"Rich", "skin":Color("75452f"), "highlight":Color("a96b49")},
    {"id":"medium", "name":"Medium", "skin":Color("9a5d3c"), "highlight":Color("c47b4c")},
    {"id":"warm", "name":"Warm", "skin":Color("b87750"), "highlight":Color("dfa073")},
    {"id":"light", "name":"Light", "skin":Color("d59a73"), "highlight":Color("f0bb91")},
    {"id":"fair", "name":"Fair", "skin":Color("e7b690"), "highlight":Color("ffd0aa")}
]

const GENDERS: Array = [
    {"id":"neutral", "name":"Neutral"},
    {"id":"woman", "name":"Woman"},
    {"id":"man", "name":"Man"}
]

# The eye scouter is independent from the suit palette. Players can pick its
# lens color and which eye wears it during campaign setup, then change both
# later from the same in-game character customization panel.
const SCOUTER_COLORS: Array = [
    {"id":"neon_green", "name":"Neon Green", "color":Color("39ff75")},
    {"id":"cyan", "name":"Cyan", "color":Color("52e7ff")},
    {"id":"electric_blue", "name":"Electric Blue", "color":Color("4b7cff")},
    {"id":"violet", "name":"Violet", "color":Color("bd8cff")},
    {"id":"magenta", "name":"Magenta", "color":Color("ff66c4")},
    {"id":"amber", "name":"Amber", "color":Color("ffd36e")},
    {"id":"orange", "name":"Orange", "color":Color("ff8d28")},
    {"id":"red", "name":"Red", "color":Color("ff5c68")}
]

const SCOUTER_EYES: Array = [
    {"id":"left", "name":"Left Eye", "scanner":"left"},
    {"id":"right", "name":"Right Eye", "scanner":"right"}
]

# Skin tone, gender/presentation and scouter settings are free identity choices.
# Outfit skins are gameplay cosmetics purchased with company cash after the
# campaign begins.
const OUTFITS: Array = [
    {"id":"operator", "name":"Neon Operator Armor", "cost":0.0, "primary":Color("171b20"), "secondary":Color("39ff75"), "neon":Color("39ff75")},
    {"id":"grid_runner", "name":"Grid Runner", "cost":12000.0, "primary":Color("17273a"), "secondary":Color("315d78"), "neon":Color("52e7ff")},
    {"id":"silicon_tech", "name":"Silicon Tech", "cost":18000.0, "primary":Color("21182f"), "secondary":Color("60447a"), "neon":Color("bd8cff")},
    {"id":"hydro_tech", "name":"Hydro Tech", "cost":24000.0, "primary":Color("0f2930"), "secondary":Color("276b75"), "neon":Color("4df0ff")},
    {"id":"executive_miner", "name":"Executive Miner", "cost":35000.0, "primary":Color("2a2418"), "secondary":Color("725c2f"), "neon":Color("ffd36e")},
    {"id":"night_shift", "name":"Night Shift", "cost":50000.0, "primary":Color("120f1d"), "secondary":Color("3f315b"), "neon":Color("ff66c4")}
]

static func skin_tone(index: int) -> Dictionary:
    return SKIN_TONES[clampi(index, 0, SKIN_TONES.size() - 1)]

static func gender(index: int) -> Dictionary:
    return GENDERS[clampi(index, 0, GENDERS.size() - 1)]

static func outfit(index: int) -> Dictionary:
    return OUTFITS[clampi(index, 0, OUTFITS.size() - 1)]

static func scouter_color(index: int) -> Dictionary:
    return SCOUTER_COLORS[clampi(index, 0, SCOUTER_COLORS.size() - 1)]

static func scouter_eye(index: int) -> Dictionary:
    return SCOUTER_EYES[clampi(index, 0, SCOUTER_EYES.size() - 1)]

static func scouter_lens_color(index: int) -> Color:
    return Color(scouter_color(index)["color"])

static func scouter_scanner_side(index: int) -> String:
    return String(scouter_eye(index)["scanner"])

static func outfit_name(index: int) -> String:
    return String(outfit(index)["name"])

static func outfit_cost(index: int) -> float:
    return float(outfit(index)["cost"])
