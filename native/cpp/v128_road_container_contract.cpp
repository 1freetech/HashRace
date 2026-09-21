#include <cassert>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

namespace fs = std::filesystem;

static std::string read_file(const fs::path& path) {
    std::ifstream input(path, std::ios::binary);
    assert(input && "required Hash Race contract file is missing");
    std::ostringstream buffer;
    buffer << input.rdbuf();
    return buffer.str();
}

static void require(const std::string& text, const std::string& token) {
    assert(text.find(token) != std::string::npos);
}

int main() {
    const fs::path root = fs::current_path();
    const fs::path asset_path = root / "Godot/art/buildings/c01_mining_container.svg";
    assert(fs::exists(asset_path));

    const std::string asset = read_file(asset_path);
    const std::string world = read_file(root / "Godot/scripts/world_v128.gd");
    const std::string scene = read_file(root / "Godot/scenes/world.tscn");
    const std::string validator = read_file(root / "Godot/scripts/validate_modular_scripts.gd");
    const std::string capture = read_file(root / "Godot/scripts/capture_screenshot.gd");

    require(asset, "<svg");
    require(asset, "width=\"128\"");
    require(asset, "height=\"102\"");
    require(asset, "COMMAND");
    require(asset, "CENTER");

    require(world, "extends \"res://scripts/world_v127.gd\"");
    require(world, "V128_CONTAINER_PATH := \"res://art/buildings/c01_mining_container.svg\"");
    require(world, "CITY_ROAD_STYLES");
    require(world, "_v128_draw_city_road");
    require(world, "_v123_draw_ground");
    require(world, "_draw_mining_hq");
    require(world, "_v128_draw_container_sprite");
    assert(world.find("super._v115_draw_live_site") == std::string::npos);

    for (const std::string token : {
        "hashrace_v128_road_cleanup_revision",
        "hashrace_v128_container_asset_live",
        "hashrace_v128_single_road_stack"
    }) {
        require(world, token);
        require(capture, token);
    }

    require(scene, "world_v129.gd");
    require(validator, "world_v128.gd");
    std::cout << "Hash Race C++ v0.128 road/container contract: PASS\n";
    return 0;
}
