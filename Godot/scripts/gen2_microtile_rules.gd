extends RefCounted
class_name HashRaceGen2Microtiles

# Hash Race adaptation of the MIT-licensed Pokemon-gen-2-style-tilemap idea:
# build larger terrain/objects from named 8x8 microtiles and deterministic
# variants instead of painting arbitrary sub-pixel/vector detail.
# No Pokemon artwork is bundled or copied.

const MICRO_TILE_SIZE: float = 8.0
const CELL_MICROTILES: int = 6
const CELL_SIZE: float = MICRO_TILE_SIZE * float(CELL_MICROTILES)

const NORTH: int = 1
const EAST: int = 2
const SOUTH: int = 4
const WEST: int = 8

const MOTIF_NAMES := [
    "path",
    "path_gravel",
    "grass_flat",
    "grass_tuft",
    "water_wave",
    "lot_panel",
    "plaza_paver",
    "building_cladding",
]

static func neighbor_mask(cells: Dictionary, cell: Vector2i, tile_id: int) -> int:
    var mask: int = 0
    if int(cells.get(cell + Vector2i.UP, -999999)) == tile_id:
        mask |= NORTH
    if int(cells.get(cell + Vector2i.RIGHT, -999999)) == tile_id:
        mask |= EAST
    if int(cells.get(cell + Vector2i.DOWN, -999999)) == tile_id:
        mask |= SOUTH
    if int(cells.get(cell + Vector2i.LEFT, -999999)) == tile_id:
        mask |= WEST
    return mask

static func has_neighbor(mask: int, direction: int) -> bool:
    return (mask & direction) != 0

static func motif_slots(seed: int, count: int) -> Array[Vector2i]:
    var slots: Array[Vector2i] = []
    var used: Dictionary = {}
    var total: int = CELL_MICROTILES * CELL_MICROTILES
    var wanted: int = clampi(count, 0, total)
    var state: int = absi(seed) + 17
    while slots.size() < wanted:
        state = int((state * 1103515245 + 12345) % 2147483647)
        var idx: int = state % total
        var guard: int = 0
        while used.has(idx) and guard < total:
            idx = (idx + 7) % total
            guard += 1
        if used.has(idx):
            break
        used[idx] = true
        slots.append(Vector2i(idx % CELL_MICROTILES, int(idx / CELL_MICROTILES)))
    return slots

static func micro_origin(cell_origin: Vector2, slot: Vector2i) -> Vector2:
    return cell_origin + Vector2(float(slot.x), float(slot.y)) * MICRO_TILE_SIZE

static func snap_to_micro(value: float) -> float:
    return roundf(value / MICRO_TILE_SIZE) * MICRO_TILE_SIZE

static func snap_point(value: Vector2) -> Vector2:
    return Vector2(snap_to_micro(value.x), snap_to_micro(value.y))

static func source_contract_ready() -> bool:
    var slots: Array[Vector2i] = motif_slots(42, 6)
    return (
        is_equal_approx(CELL_SIZE, 48.0)
        and slots.size() == 6
        and MOTIF_NAMES.has("grass_flat")
        and MOTIF_NAMES.has("building_cladding")
        and neighbor_mask({Vector2i.ZERO: 1, Vector2i.RIGHT: 1}, Vector2i.ZERO, 1) == EAST
    )
