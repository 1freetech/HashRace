#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <regex>
#include <set>

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

static void require_world_inherits(const std::string& scene, const std::string& wanted) {
    std::smatch match;
    if (!std::regex_search(scene, match, std::regex("script = ExtResource\\(\\\"([^\\\"]+)\\\"\\)")))
        throw std::runtime_error("live world root has no script");
    const auto id = match[1].str();
    const std::regex resource("path=\\\"(res://[^\\\"]+)\\\" type=\\\"Script\\\" id=\\\"" + id + "\\\"");
    if (!std::regex_search(scene, match, resource)) throw std::runtime_error("world script resource missing");
    auto path = match[1].str();
    std::set<std::string> visited;
    bool found = false;
    const std::regex parent("^extends \\\"(res://[^\\\"]+)\\\"");
    while (path.rfind("res://", 0) == 0) {
        if (!visited.insert(path).second) throw std::runtime_error("cyclic world inheritance");
        if (path == "res://scripts/" + wanted) found = true;
        const auto source = read_text("Godot/" + path.substr(6));
        if (!std::regex_search(source, match, parent)) break;
        path = match[1].str();
    }
    if (!found) throw std::runtime_error("live world does not inherit " + wanted);
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
        require_world_inherits(scene, "world_v128.gd");
        require_contains(validator, "world_v128.gd");
        std::cout << "Hash Race v0.128 C++ road/container behavior contract: PASS\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Hash Race v0.128 C++ contract FAIL: " << error.what() << '\n';
        return 1;
    }
}
