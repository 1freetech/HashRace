extends RefCounted
class_name HashRaceCharacterCustomization

const DEFAULT_SKIN_TONE: int = 2
const DEFAULT_GENDER: int = 0
const DEFAULT_OUTFIT: int = 0

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
