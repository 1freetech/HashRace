extends RefCounted
class_name HashRacePriorityAssetCatalog

# Priority assets are game-source assets, not design references.
# The campus composition image is retained in the runtime asset catalog so
# systems may sample/slice it into authored components during live integration.
const CAMPUS_PRIORITY_ASSET := "res://art/priority/hashrace_campus_priority_asset.png"

static func campus_texture() -> Texture2D:
    if not ResourceLoader.exists(CAMPUS_PRIORITY_ASSET):
        return null
    return load(CAMPUS_PRIORITY_ASSET) as Texture2D

static func debug_ready() -> bool:
    return ResourceLoader.exists(CAMPUS_PRIORITY_ASSET)
