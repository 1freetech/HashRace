extends RefCounted
class_name HashRaceCharacterCustomization

const DEFAULT_SKIN_TONE: int = 2
const DEFAULT_GENDER: int = 0
const DEFAULT_OUTFIT: int = 0
const DEFAULT_HAIR_STYLE: int = 0
const DEFAULT_HAIR_COLOR: int = 1
const DEFAULT_SUIT_COLOR: int = 0
const DEFAULT_ACCENT_COLOR: int = 0

const SKIN_TONES: Array = [
    {"id":"deep", "name":"Deep", "skin":Color("5d3526"), "highlight":Color("875239")},
    {"id":"rich", "name":"Rich", "skin":Color("75452f"), "highlight":Color("a96b49")},
    {"id":"medium", "name":"Medium", "skin":Color("9a5d3c"), "highlight":Color("c47b4c")},
    {"id":"warm", "name":"Warm", "skin":Color("b87750"), "highlight":Color("dfa073")},
    {"id":"light", "name":"Light", "skin":Color("d59a73"), "highlight":Color("f0bb91")},
    {"id":"fair", "name":"Fair", "skin":Color("e7b690"), "highlight":Color("ffd0aa")}
]

const HAIR_STYLES: Array = [
    {"id":"short", "name":"Short"},
    {"id":"fade", "name":"Fade"},
    {"id":"waves", "name":"Waves"},
    {"id":"locs", "name":"Locs"},
    {"id":"curly", "name":"Curly"},
    {"id":"long", "name":"Long"}
]

const HAIR_COLORS: Array = [
    {"id":"black", "name":"Black", "color":Color("151318")},
    {"id":"dark_brown", "name":"Dark Brown", "color":Color("33221d")},
    {"id":"brown", "name":"Brown", "color":Color("60402d")},
    {"id":"auburn", "name":"Auburn", "color":Color("7b3829")},
    {"id":"blonde", "name":"Blonde", "color":Color("c7a65a")},
    {"id":"silver", "name":"Silver", "color":Color("b8c0c7")}
]

const SUIT_COLORS: Array = [
    {"id":"operator", "name":"Operator White", "color":Color("e9eeee")},
    {"id":"graphite", "name":"Graphite", "color":Color("313940")},
    {"id":"navy", "name":"Navy", "color":Color("243d62")},
    {"id":"industrial_blue", "name":"Industrial Blue", "color":Color("326a86")},
    {"id":"forest", "name":"Forest", "color":Color("355e48")},
    {"id":"burgundy", "name":"Burgundy", "color":Color("703b46")}
]

const ACCENT_COLORS: Array = [
    {"id":"orange", "name":"Safety Orange", "color":Color("e07a2f")},
    {"id":"green", "name":"Miner Green", "color":Color("39ff75")},
    {"id":"cyan", "name":"Grid Cyan", "color":Color("52e7ff")},
    {"id":"gold", "name":"Executive Gold", "color":Color("d8b65a")}
]

const GENDERS: Array = [
    {"id":"neutral", "name":"Neutral"},
    {"id":"woman", "name":"Woman"},
    {"id":"man", "name":"Man"}
]

# Skin tone and gender/presentation are free identity choices. Outfit skins are
# gameplay cosmetics purchased with company cash after the campaign begins.
# v0.053 updates the starter Operator Suit to the approved light shell + orange
# armor-pad palette while retaining its neon-green scanner display.
const OUTFITS: Array = [
    {"id":"operator", "name":"Operator Suit", "cost":0.0, "primary":Color("e9eeee"), "secondary":Color("e07a2f"), "neon":Color("39ff75")},
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

static func outfit_name(index: int) -> String:
    return String(outfit(index)["name"])

static func outfit_cost(index: int) -> float:
    return float(outfit(index)["cost"])


static func hair_style(index: int) -> Dictionary:
    return HAIR_STYLES[clampi(index, 0, HAIR_STYLES.size() - 1)]

static func hair_color(index: int) -> Dictionary:
    return HAIR_COLORS[clampi(index, 0, HAIR_COLORS.size() - 1)]

static func suit_color(index: int) -> Dictionary:
    return SUIT_COLORS[clampi(index, 0, SUIT_COLORS.size() - 1)]

static func accent_color(index: int) -> Dictionary:
    return ACCENT_COLORS[clampi(index, 0, ACCENT_COLORS.size() - 1)]
