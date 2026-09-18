class_name HashRaceItemLibrary
extends RefCounted

const ITEM_DIRECTORY := "res://data/items/"
const ITEM_SCRIPT := preload("res://data/item_resource.gd")

static func load_catalog() -> Array:
    var result: Array = []
    var dir := DirAccess.open(ITEM_DIRECTORY)
    if dir == null:
        push_error("HashRaceItemLibrary: missing %s" % ITEM_DIRECTORY)
        return result

    var filenames: Array[String] = []
    dir.list_dir_begin()
    var filename := dir.get_next()
    while filename != "":
        if not dir.current_is_dir() and filename.ends_with(".tres"):
            filenames.append(filename)
        filename = dir.get_next()
    dir.list_dir_end()
    filenames.sort()

    for item_file in filenames:
        var resource = load(ITEM_DIRECTORY + item_file)
        if resource == null or resource.get_script() != ITEM_SCRIPT:
            continue
        var item_id := String(resource.get("id"))
        if item_id.is_empty():
            push_warning("HashRaceItemLibrary: item has no id: %s" % item_file)
            continue
        result.append(resource)
    return result

static func index_by_id(resources: Array) -> Dictionary:
    var result := {}
    for raw in resources:
        if raw == null:
            continue
        var item_id := String(raw.get("id"))
        if not item_id.is_empty():
            result[item_id] = raw
    return result
