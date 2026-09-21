#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>

static std::string read_text(const std::string& path) {
    std::ifstream in(path);
    if (!in) throw std::runtime_error("missing file: " + path);
    std::ostringstream out;
    out << in.rdbuf();
    return out.str();
}

static void require_contains(const std::string& text, const std::string& token) {
    if (text.find(token) == std::string::npos) throw std::runtime_error("missing contract token: " + token);
}

int main() {
    try {
        const auto world = read_text("Godot/scripts/world_v128.gd");
        const auto scene = read_text("Godot/scenes/world.tscn");
        const auto validator = read_text("Godot/scripts/validate_modular_scripts.gd");
        const auto capture = read_text("Godot/scripts/capture_screenshot.gd");
        require_contains(world, "extends \"res://scripts/world_v127.gd\"");
        require_contains(world, "V128_CONTAINER_PATH");
        require_contains(world, "CITY_ROAD_STYLES");
        require_contains(world, "_v128_draw_city_road");
        require_contains(world, "_draw_mining_hq");
        require_contains(world, "_v128_draw_container_sprite");
        require_contains(world, "hashrace_v128_road_cleanup_revision");
        require_contains(world, "hashrace_v128_single_road_stack");
        require_contains(capture, "hashrace_v128_road_cleanup_revision");
        require_contains(capture, "hashrace_v128_single_road_stack");
        require_contains(scene, "world_v130.gd");
        require_contains(validator, "world_v128.gd");
        std::cout << "Hash Race v0.128 C++ road/container behavior contract: PASS\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Hash Race v0.128 C++ contract FAIL: " << error.what() << '\n';
        return 1;
    }
}
