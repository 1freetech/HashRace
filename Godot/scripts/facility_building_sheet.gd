extends RefCounted
class_name HashRaceFacilityBuildingSheet

# Authored 3x3 facility sprite sheet. Every frame is 160x128 pixels and shares
# one ground baseline so the live world can preserve the existing collision,
# doorway, navigation, and interaction contracts while replacing procedural art.
const TEXTURE_PATH := "res://art/buildings/facility_buildings_sheet.svg"
const FRAME_SIZE := Vector2i(160, 128)
const COLUMNS := 3
const ROWS := 3

const FRAME_COMMAND_CENTER := 0
const FRAME_RIVAL_HQ := 1
const FRAME_SEMICONDUCTOR_FAB := 2
const FRAME_AI_LAB := 3
const FRAME_PARTNER_OFFICE := 4
const FRAME_MACHINE_MARKET := 5
const FRAME_POWER_UTILITY := 6
const FRAME_BANK := 7
const FRAME_LAND_OFFICE := 8

static func frame_rect(frame: int) -> Rect2:
    var safe := clampi(frame, 0, COLUMNS * ROWS - 1)
    var col := safe % COLUMNS
    var row := int(safe / COLUMNS)
    return Rect2(Vector2(float(col * FRAME_SIZE.x), float(row * FRAME_SIZE.y)), Vector2(FRAME_SIZE))

static func frame_for(entity: Dictionary) -> int:
    var kind := String(entity.get("kind", ""))
    match kind:
        "hq":
            return FRAME_COMMAND_CENTER
        "rival":
            return FRAME_RIVAL_HQ
        "machines":
            return FRAME_MACHINE_MARKET
        "power":
            return FRAME_POWER_UTILITY
        "bank":
            return FRAME_BANK
        "land":
            return FRAME_LAND_OFFICE
        "partner":
            # Partner indices stay deterministic. The first two partner families
            # read as semiconductor/AI facilities; the remainder use the shared
            # office/lab frame instead of recolored copies of the player HQ.
            var partner_idx := int(entity.get("partner_idx", 0))
            if partner_idx % 3 == 0:
                return FRAME_SEMICONDUCTOR_FAB
            if partner_idx % 3 == 1:
                return FRAME_AI_LAB
            return FRAME_PARTNER_OFFICE
    return FRAME_PARTNER_OFFICE

static func valid_texture(texture: Texture2D) -> bool:
    return texture != null \
        and texture.get_width() == FRAME_SIZE.x * COLUMNS \
        and texture.get_height() == FRAME_SIZE.y * ROWS
